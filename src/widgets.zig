const std = @import("std");
const testing = std.testing;
const mutt = @import("mutt");
const sdl = @import("sdl.zig").sdl;
const Allocator = std.mem.Allocator;
const EventHandler = @import("event_handler.zig").EventHandler;

pub const WidgetInfo = struct {
    name: ?[]const u8 = null,
    display: bool = true,
    has_children: bool = false,
    children: ?std.ArrayListUnmanaged(Widget) = null,
    parent: ?Widget = null,
};

pub const WidgetType = enum {
    root,
};

pub const Widget = union(WidgetType) {
    const Self = @This();
    root: *Root,

    pub fn init(kind: WidgetType, allocator: Allocator, event_handler: *EventHandler) !Self {
        var self: Self = undefined;
        switch (kind) {
            .root => {
                self.root = try Root.init(allocator, event_handler);
                return self;
            },
        }
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        switch (self.*) {
            .root => self.root.deinit(allocator),
        }
    }

    pub fn display(self: *Self, renderer: *sdl.SDL_Renderer) void {
        switch (self.*) {
            .root => self.root.display(renderer),
        }
    }
};

const Root = struct {
    const Self = @This();
    info: WidgetInfo,
    quit: bool = false,

    pub fn init(allocator: Allocator, event_handler: *EventHandler) !*Self {
        var self = allocator.create(Self) catch return error.GooberFailedRootInit;
        self.info = .{ .name = "goober__root" };

        // Register `quit` event
        event_handler.register(allocator, sdl.SDL_QUIT, self, (struct {
            pub fn callback(this: *anyopaque, ev: sdl.SDL_Event) void {
                if (ev.type == sdl.SDL_QUIT) {
                    const self_: *Self = @ptrCast(@alignCast(this));
                    self_.quit = true;
                }
            }
        }).callback) catch return error.GooberFailedRootInit;

        return self;
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.destroy(self);
    }

    pub fn display(_: *Self, renderer: *sdl.SDL_Renderer) void {
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
        _ = sdl.SDL_RenderClear(renderer);
        // sdl.SDL_RenderPresent(renderer);
        // sdl.SDL_Delay(1000 / 60);
    }
};
