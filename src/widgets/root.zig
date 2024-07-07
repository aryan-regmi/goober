const std = @import("std");
const widget = @import("../widget.zig");
const sdl = @import("../sdl.zig").sdl;
const Allocator = std.mem.Allocator;
const EventHandler = @import("../event_handler.zig").EventHandler;

pub const Root = struct {
    pub usingnamespace widget.Widget(Self);

    const Self = @This();
    info: widget.WidgetInfo,
    quit: bool = false,

    pub fn init(allocator: Allocator, event_handler: *EventHandler) anyerror!*Self {
        var self = try allocator.create(Self);
        self.info = .{ .name = "goober__root" };

        // Register `quit` event
        try event_handler.register(allocator, sdl.SDL_QUIT, self, (struct {
            pub fn callback(self_: *anyopaque, ev: sdl.SDL_Event) void {
                if (ev.type == sdl.SDL_QUIT) {
                    const s: *Self = @ptrCast(@alignCast(self_));
                    s.quit = true;
                }
            }
        }).callback);

        return self;
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.destroy(self);
    }

    pub fn display(self: *Self, renderer: *sdl.SDL_Renderer) void {
        _ = self; // autofix
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
        _ = sdl.SDL_RenderClear(renderer);
        sdl.SDL_RenderPresent(renderer);
        sdl.SDL_Delay(1000 / 60);
    }
};
