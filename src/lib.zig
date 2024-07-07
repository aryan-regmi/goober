const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Root = @import("widgets/root.zig").Root;
const EventHandler = @import("event_handler.zig").EventHandler;

pub const sdl = @import("sdl.zig").sdl;
pub const widget = @import("widget.zig");

// TODO: Convert panics to zig errors?

/// Panics with the error returned by `SDL_GetError`.
fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, sdl.SDL_GetError()) orelse "Unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

pub const Gui = struct {
    const Self = @This();
    allocator: Allocator,
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
    event_handler: EventHandler,
    root: *Root,

    // TODO: Take in config struct to pass width, height, x & y pos, fps, background color, etc?
    pub fn init(allocator: Allocator, title: [*c]const u8, width: usize, height: usize) Self {
        // Init SDL
        if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS) != 0) {
            sdlPanic();
        }

        // Create window
        const w: c_int = @intCast(width);
        const h: c_int = @intCast(height);
        const window = sdl.SDL_CreateWindow(title, sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, w, h, sdl.SDL_WINDOW_OPENGL) orelse {
            sdlPanic();
        };

        // Create renderer
        const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse {
            sdlPanic();
        };

        // Init event handler
        var event_handler = EventHandler{};

        // Init root
        const root = Root.init(allocator, &event_handler) catch @panic("Unable to initalize the root widget");

        return Self{
            .allocator = allocator,
            .window = window,
            .renderer = renderer,
            .event_handler = event_handler,
            .root = root,
        };
    }

    pub fn deinit(self: *Self) void {
        // TODO: Loop thru and deinit all children widgets!
        self.root.deinit(self.allocator);

        // Deinit event handler
        self.event_handler.deinit(self.allocator);

        // Free SDL resources
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_DestroyWindow(self.window);
        sdl.SDL_Quit();
    }

    pub fn start(self: *Self) void {
        while (self.root.quit != true) {
            self.event_handler.handleEvents();

            // TODO: Loop thru all children and call `display`
            self.root.display(self.renderer);
        }
    }

    pub fn registerEvent(self: *Self, event_type: sdl.SDL_EventType, ctx: *anyopaque, callback: EventHandler.Callback) !void {
        // TODO: Check that `ctx` is a valid widget?
        try self.event_handler.register(self.allocator, event_type, ctx, callback);
    }
};

test "Init Gui" {
    var gui = Gui.init(testing.allocator, "Hello World!", 720, 480);
    defer gui.deinit();

    gui.start();
}

test {
    comptime {
        testing.refAllDecls(@This());
    }
}
