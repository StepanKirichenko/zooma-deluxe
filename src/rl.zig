pub const Color = extern struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
};

pub const Vector2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
};

pub const Key = enum(c_int) {
    a = 65,
    d = 68,
    s = 83,
    w = 87,
};

extern "c" fn InitWindow(width: c_int, height: c_int, title: [*:0]const u8) void;
extern "c" fn SetTargetFPS(fps: c_int) void;
extern "c" fn CloseWindow() void;
extern "c" fn WindowShouldClose() bool;
extern "c" fn BeginDrawing() void;
extern "c" fn EndDrawing() void;
extern "c" fn ClearBackground(color: Color) void;
extern "c" fn GetFrameTime() f32;
extern "c" fn Vector2Scale(vector: Vector2, scale: f32) Vector2;
extern "c" fn Vector2Add(vector1: Vector2, vector2: Vector2) Vector2;

// Input
extern "c" fn IsKeyPressed(key: Key) bool;
extern "c" fn IsKeyDown(key: Key) bool;

// Drawing Shapes
extern "c" fn DrawCircleV(center: Vector2, radius: f32, color: Color) void;

pub fn initWindow(width: u32, height: u32, title: [*:0]const u8) void {
    InitWindow(@intCast(width), @intCast(height), title);
}

pub fn setTargetFPS(fps: u32) void {
    SetTargetFPS(@intCast(fps));
}

pub fn closeWindow() void {
    CloseWindow();
}

pub fn windowShouldClose() bool {
    return WindowShouldClose();
}

pub fn beginDrawing() void {
    BeginDrawing();
}

pub fn endDrawing() void {
    EndDrawing();
}

pub fn clearBackground(color: Color) void {
    ClearBackground(color);
}

pub const getFrameTime = GetFrameTime;

// Input
pub const isKeyPressed = IsKeyPressed;
pub const isKeyDown = IsKeyDown;

// Shapes
pub const drawCircleV = DrawCircleV;

// Math
pub const vector2Add = Vector2Add;
pub const vector2Scale = Vector2Scale;
