const std = @import("std");
const sdl = @import("sdl.zig").sdl;
const Allocator = std.mem.Allocator;

/// An event handler responsible for propagating and handling GUI events.
pub const EventHandler = struct {
    const Self = @This();
    pub const Callback = *const fn (*anyopaque, sdl.SDL_Event) void;

    const CallbackInfo = struct {
        ctx: *anyopaque,
        callback: Callback,
    };

    registered_callbacks: std.AutoHashMapUnmanaged(sdl.SDL_EventType, std.ArrayListUnmanaged(CallbackInfo)) = .{},

    /// Register an event handler.
    pub fn register(self: *Self, allocator: Allocator, ev_type: sdl.SDL_EventType, ctx: *anyopaque, callback: Callback) !void {
        const callback_list = self.registered_callbacks.getPtr(ev_type);
        if (callback_list) |cbs| {
            try cbs.append(allocator, CallbackInfo{ .ctx = ctx, .callback = callback });
        } else {
            var new_callback_list = std.ArrayListUnmanaged(CallbackInfo){};
            try new_callback_list.append(allocator, CallbackInfo{ .ctx = ctx, .callback = callback });
            try self.registered_callbacks.put(allocator, ev_type, new_callback_list);
        }
    }

    /// Remove an event handler.
    pub fn remove(self: *Self, ev_type: sdl.SDL_EventType, ctx: *anyopaque) void {
        const list = self.registered_callbacks.getPtr(ev_type);
        if (list) |cbs| {
            for (cbs.items, 0..) |cb_info, i| {
                if (cb_info.ctx == ctx) {
                    _ = cbs.swapRemove(i);
                    return;
                }
            }
        }
    }

    /// Poll events and handle them with their specified callbacks.
    pub fn handleEvents(self: *Self) void {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            const callbacks = self.registered_callbacks.getPtr(event.type);
            if (callbacks) |cbs| {
                for (cbs.items) |cb| {
                    cb.callback(cb.ctx, event);
                }
            }
        }
    }

    /// Unregister all event handlers/listeners.
    pub fn deinit(self: *Self, allocator: Allocator) void {
        var iter = self.registered_callbacks.valueIterator();
        while (iter.next()) |cb_list| {
            cb_list.deinit(allocator);
        }
        self.registered_callbacks.deinit(allocator);
    }
};
