const std = @import("std");
const Allocator = std.mem.Allocator;
const SDL = @import("sdl2");

pub fn Widget(comptime T: type) type {
    _ = T;
    return struct {};
}

pub const WidgetInfo = struct {
    has_children: bool = false,
    children: ?std.ArrayListUnmanaged(ErasedWidget) = null,
    parent: ?*ErasedWidget = null,
    name: ?[]const u8 = null,
};

pub const ErasedWidget = struct {
    ptr: *anyopaque,
};

pub const Gui = struct {
    allocator: Allocator,
    window: *SDL.SDL_Window,
    renderer: *SDL.SDL_Renderer,
    root: Widget,
};
