# name es el nombre del gif que debe estar en Graphics/Pictures/
# message es el mensaje que se mostrará mientras se reproduce el gif
# looping indica si el gif debe reproducirse en bucle
def play_gif(name, message = nil, looping = true)
  spr = Sprite.new
  spr.bitmap = Bitmap.new("Graphics/Pictures/#{name}")
  spr.bitmap.looping = looping
  spr.bitmap.play if spr.bitmap.animated?
  pbMessage(_INTL("{1}", message)) if message
  if !$game_message || !$game_message.busy?
    spr.dispose
  end
end