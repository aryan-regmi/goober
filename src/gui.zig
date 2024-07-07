const std = @import("std");
const testing = std.testing;
const sdl = @import("sdl.zig").sdl;
const widgets = @import("widgets.zig");
const Allocator = std.mem.Allocator;
const EventHandler = @import("event_handler.zig").EventHandler;

pub const Gui = struct {
    const Self = @This();
    allocator: Allocator,
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
    event_handler: EventHandler,
    root: widgets.Widget,

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

        // Init event handler and root
        var event_handler = EventHandler{};
        const root = try widgets.Widget.init(.root, allocator, &event_handler);

        return Self{
            .allocator = allocator,
            .window = window,
            .renderer = renderer,
            .event_handler = event_handler,
            .root = root,
        };
    }

    pub fn deinit(self: *Self) void {
        // TODO: Loop thru and deinit all children widgets
        self.root.deinit(self.allocator);

        // Deinit event handler
        self.event_handler.deinit(self.allocator);

        // Deinit SDL
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_DestroyWindow(self.window);
        sdl.SDL_Quit();
    }

    pub fn run(self: *Self) void {
        while (self.root.root.quit != true) {
            self.event_handler.handleEvents();

            // TODO: Loop thru all children and call `display`
            self.root.display(self.renderer);
            sdl.SDL_RenderPresent(self.renderer);
            sdl.SDL_Delay(1000 / 60);
        }
    }
};

test "Init Gui" {
    var gui = try Gui.init(testing.allocator, "Hello World", .{});
    defer gui.deinit();
    gui.run();
}
