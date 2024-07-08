const std = @import("std");
const testing = std.testing;
const mutt = @import("mutt");
const sdl = @import("sdl.zig").sdl;
const Allocator = std.mem.Allocator;
const EventHandler = @import("event_handler.zig").EventHandler;
const Gui = @import("lib.zig").Gui;

/// Types of possible widgets.
pub const WidgetType = enum {
    root,
};

/// A widget/component of the GUI.
pub const Widget = union(WidgetType) {
    const Self = @This();

    root: Root,

    /// Initialize the widget.
    pub fn init(kind: WidgetType) !Self {
        var self: Self = undefined;
        switch (kind) {
            .root => {
                self.root = try Root.init();
                return self;
            },
        }
    }

    /// Display/render the widget.
    pub fn display(self: *Self, renderer: *sdl.SDL_Renderer) void {
        switch (self.*) {
            .root => |*r| r.display(renderer),
        }
    }

    /// Get the widget's info.
    pub fn info(self: *Self) WidgetInfo {
        switch (self.*) {
            .root => |*r| return r.info,
        }
    }

    /// Add an event listener to the widget.
    pub fn addEventListener(self: *Self, ctx: *Gui, event_type: sdl.SDL_EventType, callback: EventHandler.Callback) !void {
        switch (self.*) {
            .root => |*r| try ctx.event_handler.register(ctx.allocator, event_type, r, callback),
        }
    }
};

/// The parent of all widgets.
pub const Root = struct {
    const Self = @This();

    info: WidgetInfo,
    quit: bool = false,

    pub fn init() !Self {
        return Self{ .info = .{ .name = "goober__root" } };
    }

    pub fn display(_: *Self, renderer: *sdl.SDL_Renderer) void {
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
        _ = sdl.SDL_RenderClear(renderer);
    }
};

/// Information about a widget.
pub const WidgetInfo = struct {
    name: ?[]const u8 = null,
    display: bool = true,
    has_children: bool = false,
    parent: ?usize = null,
};
