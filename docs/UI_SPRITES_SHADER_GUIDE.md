# UI Sprites Shader Integration Guide

This guide explains how to replace the placeholder UI sprites with shader-based geometry components that don't require image files.

## Components Created

### 1. Socket Visual (`components/socket_visual.tscn`)
- **File**: `components/socket_visual.tscn`
- **Shader**: `shaders/socket.gdshader`
- **What it creates**: A brass ring with an amber glowing center when lit
- **Parameters**:
  - `amber_color`: Warm amber glow color (default: #E8B86A)
  - `brass_color`: Brass ring color (default: #B47333)
  - `teal_color`: Dark teal background color (default: #0F2A33)
  - `is_lit`: Controls the amber glow (true = glowing, false = dark)

### 2. Jack Visual (`components/jack_visual.tscn`)
- **File**: `components/jack_visual.tscn`
- **Shader**: `shaders/jack.gdshader`
- **What it creates**: A red rubber plug with a brass tip
- **Parameters**:
  - `red_color`: Red rubber body color (default: #C14B4B)
  - `brass_color`: Brass tip color (default: #B47333)

### 3. Patience Light Visual (`components/patience_light_visual.tscn`)
- **File**: `components/patience_light_visual.tscn`
- **Shader**: `shaders/patience_light.gdshader`
- **What it creates**: A mint-green indicator light with a brass collar
- **Parameters**:
  - `mint_color`: Mint green light color (default: #7AAE9A)
  - `brass_color`: Brass collar color (default: #B47333)
  - `is_on`: Controls the brightness and glow (true = bright, false = dim)

## Integration Steps

### Replace Socket Visual
1. Open `components/socket.tscn`
2. Select the `Visual` ColorRect node
3. Either:
   - Replace it with an instance of `socket_visual.tscn`, OR
   - Apply the `socket.gdshader` material to the existing ColorRect
4. Update `scripts/socket.gd` to control the `is_lit` parameter:
   ```gdscript
   @export var lit: bool = true:
       set(value):
           lit = value
           if is_node_ready() and $Visual.material is ShaderMaterial:
               ($Visual.material as ShaderMaterial).set_shader_parameter("is_lit", lit)
   ```

### Replace Jack Visual
1. Open `components/cable.tscn`
2. Select the `Jack` Sprite2D node
3. Replace it with an instance of `jack_visual.tscn`
4. Adjust the size and position as needed

### Replace Patience Light Visual
1. Find where patience lights are used in the switchboard scene
2. Replace the existing ColorRect nodes with instances of `patience_light_visual.tscn`
3. Update the controlling script to set the `is_on` parameter based on game state

## Benefits of Shader-Based UI

- **No image files needed**: All graphics are procedurally generated
- **Scalable**: Works at any resolution without pixelation
- **Customizable**: Easy to tweak colors and effects via shader parameters
- **Consistent style**: Matches the game's color palette perfectly
- **Small file size**: No additional asset files to manage

## Color Palette Reference

These colors match the game's established palette from `docs/STYLE_GUIDE.md`:

- **Deep Teal**: #0F2A33 (backgrounds)
- **Mid Teal**: #173E4A (shadows)
- **Amber**: #E8B86A (lights, glow)
- **Brass**: #B47333 (metallic parts)
- **Mint**: #7AAE9A (indicator lights)
- **Red**: #C14B4B (telephone cables)
- **Bone White**: #F1E4C8 (text)

## Testing

After integration, test that:
1. Socket lights glow when lit and dim when not
2. Jack visual appears correctly at the end of cables
3. Patience lights respond to game state changes
4. All colors match the game's aesthetic