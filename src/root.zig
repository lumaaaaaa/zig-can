const std = @import("std");
const linux = std.os.linux;
const Io = std.Io;

// constant(s) missing from Zig std
const CAN_RAW: i32 = 1;
const CAN_MAX_DLEN: u32 = 8;

// minimal linux/can.h compatible struct defs
pub const sockaddr_can = extern struct {
    can_family: linux.sa_family_t = linux.AF.CAN,
    can_ifindex: i32,
    can_addr: extern union {
        // transport protocol class address information (e.g. ISOTP)
        tp: extern struct {
            rx_id: u32,
            tx_id: u32,
        },

        // J1939 address information
        j1939: extern struct {
            name: u64,
            pgn: u32,
            addr: u8,
        },

        // reserved for future CAN protocols address information
    } = .{ .tp = .{ .rx_id = 0x0, .tx_id = 0x0 } }, // placeholder initial values
};

pub const Frame = extern struct {
    can_id: u32,
    len: u8, // this is also known as DLC (legacy)
    pad: u8,
    reserved: u8, // also padding
    len8_dlc: u8,
    data: [CAN_MAX_DLEN]u8,
};

pub const Socket = struct {
    fd: linux.fd_t, // file descriptor associated with the socket

    pub fn open(io: std.Io, interface_name: []const u8) !Socket {
        const fd = linux.socket(linux.PF.CAN, linux.SOCK.RAW, CAN_RAW);
        switch (linux.errno(fd)) {
            .SUCCESS => {},
            .ACCES => return error.AccessDenied,
            .AFNOSUPPORT => return error.AddressFamilyUnsupported,
            .MFILE, .NFILE => return error.FdExhaustion,
            .NOBUFS, .NOMEM => return error.OutOfMemory,
            else => return error.UnknownSocketError,
        }
        errdefer _ = linux.close(@intCast(fd));

        const name = try Io.net.Interface.Name.fromSlice(interface_name);
        const interface = try name.resolve(io);
        if (interface.isNone()) {
            return error.InterfaceNotFound;
        }

        var addr = sockaddr_can{ .can_ifindex = @intCast(interface.index) };
        const status = linux.bind(@intCast(fd), @as(*const linux.sockaddr, @ptrCast(&addr)), @sizeOf(sockaddr_can));
        switch (linux.errno(status)) {
            .SUCCESS => {},
            .NODEV => return error.InterfaceNotFound,
            .NETDOWN => return error.InterfaceDown,
            .ACCES => return error.AccessDenied,
            .INVAL => return error.InvalidAddress,
            else => return error.UnexpectedBindError,
        }

        return Socket{ .fd = @intCast(fd) };
    }

    pub fn deinit(self: *Socket) void {
        _ = linux.close(self.fd);
    }

    // Reads a single CAN frame from the socket.
    pub fn readFrame(self: Socket, frame: *Frame) !void {
        const status = linux.read(self.fd, @ptrCast(frame), @sizeOf(Frame));
        switch (linux.errno(status)) {
            .SUCCESS => {},
            .BADF => return error.BadFd,
            .INTR => return error.Interrupted,
            else => return error.ReadFailed,
        }

        if (status < @sizeOf(Frame)) return error.IncompleteRead;
    }
};
