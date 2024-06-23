const std = @import("std");
const testing = std.testing;
const SDL = @import("sdl2");

pub const Widget = @import("widget.zig").Widget;

/// Panics with the `SDL_Error`.
fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

const RootWidget = struct {
    const Self = @This();
    pub const Vtable = Widget.Vtable{
        .deinitFn = deinit,
        .showFn = show,
        .getParentFn = getParent,
        .isDisplayedFn = isDisplayed,
    };

    info: Widget.Info = .{},

    pub fn init(allocator: std.mem.Allocator) Widget {
        const root = allocator.create(Self) catch @panic("Out of memory: Unable to create `RootWidget`");
        return Widget.init(root, &RootWidget.Vtable);
    }

    fn deinit(self: *Widget, allocator: std.mem.Allocator) void {
        // Deinit widget
        const component: *Self = @ptrCast(@alignCast(self.component));
        allocator.destroy(component);

        // TODO: Deinit children

    }

    fn show(self: *Widget) anyerror!void {
        _ = self; // autofix
    }

    fn getParent(self: *Widget) ?*Widget {
        _ = self; // autofix
        return null;
    }

    fn isDisplayed(self: *Widget) bool {
        _ = self; // autofix
        return true;
    }
};

pub const Gui = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    window: *SDL.SDL_Window,
    renderer: *SDL.SDL_Renderer,
    root: Widget,

    // TODO: Take in a config struct instead (title, xpos, ypos, width, height)
    pub fn init(allocator: std.mem.Allocator, title: [*c]const u8) Self {
        // Initialize SDL
        if (SDL.SDL_Init(SDL.SDL_INIT_VIDEO | SDL.SDL_INIT_EVENTS) < 0) {
            sdlPanic();
        }

        // Initialize window
        const window = SDL.SDL_CreateWindow(
            title,
            SDL.SDL_WINDOWPOS_CENTERED,
            SDL.SDL_WINDOWPOS_CENTERED,
            720,
            480,
            SDL.SDL_WINDOW_SHOWN,
        ) orelse sdlPanic();

        // Initialize renderer
        const renderer = SDL.SDL_CreateRenderer(window, -1, SDL.SDL_RENDERER_ACCELERATED) orelse sdlPanic();

        // Initialize root
        const root = RootWidget.init(allocator);

        return Self{
            .allocator = allocator,
            .window = window,
            .renderer = renderer,
            .root = root,
        };
    }

    pub fn runEventLoop(self: *Self) void {
        mainLoop: while (true) {
            var ev: SDL.SDL_Event = undefined;

            // TODO: Add more robust handling of events!
            while (SDL.SDL_PollEvent(&ev) != 0) {
                if (ev.type == SDL.SDL_QUIT) {
                    break :mainLoop;
                }
            }

            _ = SDL.SDL_SetRenderDrawColor(self.renderer, 0xFF, 0xFF, 0xFF, 0xFF);
            _ = SDL.SDL_RenderClear(self.renderer);
            SDL.SDL_RenderPresent(self.renderer);
        }
    }

    // TODO: Go through all children and deinit the widgets!
    pub fn deinit(self: *Self) void {
        self.root.deinit(self.allocator);
    }
};

test "Create gui" {
    var gui = Gui.init(testing.allocator, "Test");
    defer gui.deinit();
    gui.runEventLoop();
}

const run_test = false;
test "Create basic window" {
    if (comptime run_test) {
        if (SDL.SDL_Init(SDL.SDL_INIT_VIDEO | SDL.SDL_INIT_EVENTS | SDL.SDL_INIT_AUDIO) < 0)
            sdlPanic();
        defer SDL.SDL_Quit();

        const window = SDL.SDL_CreateWindow(
            "SDL2 Native Demo",
            SDL.SDL_WINDOWPOS_CENTERED,
            SDL.SDL_WINDOWPOS_CENTERED,
            640,
            480,
            SDL.SDL_WINDOW_SHOWN,
        ) orelse sdlPanic();
        defer _ = SDL.SDL_DestroyWindow(window);

        const renderer = SDL.SDL_CreateRenderer(window, -1, SDL.SDL_RENDERER_ACCELERATED) orelse sdlPanic();
        defer _ = SDL.SDL_DestroyRenderer(renderer);

        mainLoop: while (true) {
            var ev: SDL.SDL_Event = undefined;
            while (SDL.SDL_PollEvent(&ev) != 0) {
                if (ev.type == SDL.SDL_QUIT)
                    break :mainLoop;
            }

            _ = SDL.SDL_SetRenderDrawColor(renderer, 0xF7, 0xA4, 0x1D, 0xFF);
            _ = SDL.SDL_RenderClear(renderer);

            SDL.SDL_RenderPresent(renderer);
        }
    }
}

test {
    comptime {
        testing.refAllDecls(@This());
    }
}
