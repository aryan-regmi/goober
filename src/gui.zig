const std = @import("std");
const testing = std.testing;
const sdl = @import("sdl.zig").sdl;
const widget = @import("widget.zig");
const Allocator = std.mem.Allocator;
const EventHandler = @import("event_handler.zig").EventHandler;

// TODO: Add iterator to get children/query for specific widgets

pub const Gui = struct {
    const Self = @This();

    pub const Config = struct {
        resizeable: bool = true,
        width: usize = 720,
        height: usize = 480,
        bg_color: struct {
            red: u8 = 0xff,
            green: u8 = 0xff,
            blue: u8 = 0xff,
            alpha: u8 = 0xff,
        } = .{},
    };

    allocator: Allocator,
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
    event_handler: EventHandler,
    widgets: std.ArrayListUnmanaged(widget.Widget),

    /// Initalize the GUI.
    pub fn init(allocator: Allocator, title: [*c]const u8, config: Config) !Self {
        // Init SDL
        if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS) != 0) {
            return error.SdlInitializationFailed;
        }

        // Create window
        const width: c_int = @intCast(config.width);
        const height: c_int = @intCast(config.height);
        const flags: u32 = flags: {
            if (config.resizeable) {
                break :flags sdl.SDL_WINDOW_OPENGL | sdl.SDL_WINDOW_RESIZABLE;
            } else {
                break :flags sdl.SDL_WINDOW_OPENGL;
            }
        };
        const window = sdl.SDL_CreateWindow(
            title,
            sdl.SDL_WINDOWPOS_UNDEFINED,
            sdl.SDL_WINDOWPOS_UNDEFINED,
            width,
            height,
            flags,
        ) orelse return error.SdlInitializationFailed;

        // Create renderer
        const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse return error.SdlInitializationFailed;

        // Add root widget to Gui
        const root = try widget.Widget.init(.root);
        var widgets = std.ArrayListUnmanaged(widget.Widget){};
        widgets.append(allocator, root) catch return error.GooberWidgetsInitFailed;

        // Register `quit` event handler (on root)
        var event_handler = EventHandler{};
        event_handler.register(allocator, sdl.SDL_QUIT, &widgets.items[0], (struct {
            pub fn callback(this: *anyopaque, ev: sdl.SDL_Event) void {
                if (ev.type == sdl.SDL_QUIT) {
                    const self_: *widget.Root = @ptrCast(@alignCast(this));
                    self_.quit = true;
                }
            }
        }).callback) catch return error.GooberFailedRootInit;

        return Self{
            .allocator = allocator,
            .window = window,
            .renderer = renderer,
            .event_handler = event_handler,
            .widgets = widgets,
        };
    }

    /// Free all resources used by the GUI.
    pub fn deinit(self: *Self) void {
        // Free widgets
        self.widgets.deinit(self.allocator);

        // Deinit event handler
        self.event_handler.deinit(self.allocator);

        // Deinit SDL
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_DestroyWindow(self.window);
        sdl.SDL_Quit();
    }

    /// Run the GUI/start the event loop.
    pub fn run(self: *Self) void {
        while (self.widgets.items[0].root.quit != true) {
            self.event_handler.handleEvents();

            // Display all widgets
            for (self.widgets.items) |*w| {
                if (w.info().display) {
                    w.display(self.renderer);
                }
            }
            sdl.SDL_RenderPresent(self.renderer);
            sdl.SDL_Delay(1000 / 60);
        }
    }

    /// Add an event listener.
    pub fn addEventListener(self: *Self, event_type: sdl.SDL_EventType, ctx: *widget.Widget, callback: EventHandler.Callback) !void {
        try self.event_handler.register(self.allocator, event_type, ctx, callback);
    }
};

test {
    var gui = try Gui.init(testing.allocator, "Hello World!", .{});
    defer gui.deinit();
    gui.run();
}
