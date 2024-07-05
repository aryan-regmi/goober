const std = @import("std");
const testing = std.testing;
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});
const widget = @import("widget.zig");
comptime {
    _ = widget;
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, sdl.SDL_GetError()) orelse "Unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

const run_test = false;
test "Init" {
    if (comptime run_test) {
        const width = 720;
        const height = 480;
        const fps = 60;

        if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS) != 0) {
            sdlPanic();
        }
        defer sdl.SDL_Quit();

        const window = sdl.SDL_CreateWindow("Hello World!", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, width, height, sdl.SDL_WINDOW_OPENGL) orelse sdlPanic();
        defer sdl.SDL_DestroyWindow(window);

        const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse sdlPanic();
        defer sdl.SDL_DestroyRenderer(renderer);

        var quit = false;
        while (!quit) {
            // Handle events
            var event: sdl.SDL_Event = undefined;
            while (sdl.SDL_PollEvent(&event) != 0) {
                switch (event.type) {
                    sdl.SDL_QUIT => quit = true,
                    else => {},
                }
            }

            // Render
            _ = sdl.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
            _ = sdl.SDL_RenderClear(renderer);
            sdl.SDL_RenderPresent(renderer);
            sdl.SDL_Delay(1000 / fps);
        }
    }
}

test {
    comptime {
        testing.refAllDecls(@This());
    }
}
