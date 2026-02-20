# name es el nombre del gif que debe estar en Graphics/Pictures/
# message es el mensaje que se mostrará mientras se reproduce el gif
# looping indica si el gif debe reproducirse en bucle
# x, y: posición del gif en la pantalla (por defecto 0, 0)
# scale_x, scale_y: escala del gif (por defecto 1.0, 1.0)
def play_gif(name, message = nil, looping = true, x = 0, y = 0, scale_x = 1.0, scale_y = 1.0)
  spr = Sprite.new
  spr.bitmap = Bitmap.new("Graphics/Pictures/#{name}")
  spr.bitmap.looping = looping
  spr.bitmap.play if spr.bitmap.animated?
  spr.x = x
  spr.y = y
  spr.zoom_x = scale_x
  spr.zoom_y = scale_y
  pbMessage(_INTL("{1}", message)) if message
  if !$game_message || !$game_message.busy?
    spr.dispose
  end
end