const std = @import("std");
const testing = std.testing;

pub const sdl = @import("sdl.zig").sdl;
pub const widgets = @import("widgets.zig");
pub const Gui = @import("gui.zig").Gui;

/// Panics with the error returned by `SDL_GetError`.
pub fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, sdl.SDL_GetError()) orelse "Unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

test {
    comptime {
        testing.refAllDecls(@This());
    }
}
