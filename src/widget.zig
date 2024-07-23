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
    button,
};

/// Information about a widget.
pub const WidgetInfo = struct {
    gui: *Gui,
    name: ?[]const u8 = null,
    display: bool = true,
    has_children: bool = false,
    parent: ?usize = null,
};

/// A widget/component of the GUI.
pub const Widget = union(WidgetType) {
    const Self = @This();

    root: Root,
    button: Button,

    /// Initialize the widget.
    pub fn init(kind: WidgetType, gui: *Gui, config: anytype) !Self {
        var self: Self = undefined;
        switch (kind) {
            .root => {
                self.root = Root.init(gui);
                return self;
            },
            .button => {
                self.button = Button.init(gui, config.onclick);
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
    pub fn addEventListener(self: *Self, event_type: sdl.SDL_EventType, callback: EventHandler.Callback) !void {
        switch (self.*) {
            .root => |*r| {
                var ctx = r.info.gui;
                try ctx.event_handler.register(ctx.allocator, event_type, r, callback);
            },
        }
    }
};

/// The parent of all widgets.
pub const Root = struct {
    const Self = @This();

    info: WidgetInfo,
    quit: bool = false,

    pub fn init(gui: *Gui) Self {
        return Self{ .info = .{
            .gui = gui,
            .name = "goober__root",
        } };
    }

    pub fn display(_: *Self, renderer: *sdl.SDL_Renderer) void {
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
        _ = sdl.SDL_RenderClear(renderer);
    }
};

pub const Button = struct {
    const Self = @This();

    info: WidgetInfo,
    onclick: ?*const fn (*Self) void,

    pub fn init(gui: *Gui, onclick: ?*const fn (*Self) void) !Self {
        return Self{
            .info = .{ .gui = gui },
            .onclick = onclick,
        };
    }
};
