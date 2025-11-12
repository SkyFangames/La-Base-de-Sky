#===============================================================================
#  Fancy Badges
#    by Luka S.J.
#
#  Renders a 3D version of a badge, and applies rotational animation
#  to spice up those scenes when you obtain Gym Badges.
#  Call it in an event via the 'script' command using:
#      renderBadgeAnimation(X)
#  Where "X" represents the internal ID of the badge
#
#  Enjoy the script, and make sure to give credit!
#===============================================================================
#  Gets the edges of the sprite for path extrusions
#-------------------------------------------------------------------------------
def analyzeBitmap3D(bitmap, reverse = false)
  points = []
  layer = 0
  x0 = reverse ? bitmap.width-1 : 0
  color0 = Color.new(0,0,0,0)
  for y in 0...bitmap.height
    handled = false
    a = []
    for x in 0...bitmap.width
      x = (bitmap.width - 1) - x if reverse
      color = bitmap.get_pixel(x,y)
      if color.alpha > 0 && color0.alpha <= 0
        a.push(x)
        handled = true
      end
      x0 = x
      color0 = color.dup
    end
    points.push(a) if handled
    points.push(nil) if !handled
  end
  return points
end
#-------------------------------------------------------------------------------
#  Checks the coordinates of the "sides" for the current rotation of the badge
#-------------------------------------------------------------------------------
def checkForSides(points1)
  points = []
  for y in 0...points1.length
    for x in 0...points1[y].length
      points.push(points1[y][x])
    end
  end
  return (points.uniq!).sort!
end
#-------------------------------------------------------------------------------
#  Method of getting gradual skews
#-------------------------------------------------------------------------------
def splitGradient(point1, point2, frames, reverse = false)
  points = []
  dif = (point1.to_f - point2.to_f)*0.5/frames.to_f
  point1 += dif*frames*0.5*(reverse ? -1 : 1)
  for i in 0...frames
    points.push(point1)
    point1 -= dif*(reverse ? -1 : 1)
  end
  return points
end
#-------------------------------------------------------------------------------
#  Alternative method of getting gradual skews
#-------------------------------------------------------------------------------
def splitGradient2(point1, point2, frames, reverse = false)
  points = []
  dif = (point1.to_f - point2.to_f)/frames.to_f
  point1 -= dif*frames if reverse
  for i in 0...frames
    points.push(point1)
    point1 += dif*(reverse ? 1 : -1)
  end
  return points
end
#-------------------------------------------------------------------------------
#  Def used for playing badge obtain animation
#-------------------------------------------------------------------------------
def renderBadgeAnimation(badge_number = 0)
  $player.badges[badge_number] = true
  height = Graphics.height
  screen = Graphics.snap_to_bitmap
  viewport = Viewport.new(0, 0, Graphics.width, height)
  viewport.z = 99999
  viewport.color = Color.new(255,255,255)
  # handling additional particles
  fp = {}
  rangle = []
  for i in 0...8; rangle.push((300/8)*i +  15); end
  for j in 0...8
    fp["#{j}"] = Sprite.new(viewport)
    fp["#{j}"].bitmap = pbBitmap("Graphics/Transitions/badgeShine")
    fp["#{j}"].ox = 0
    fp["#{j}"].oy = fp["#{j}"].bitmap.height/2
    fp["#{j}"].opacity = 0
    fp["#{j}"].zoom_x = 0
    fp["#{j}"].zoom_y = 0
    fp["#{j}"].x = viewport.rect.width/2
    fp["#{j}"].y = viewport.rect.height/2
    a = rand(rangle.length)
    fp["#{j}"].angle = rangle[a]
    fp["#{j}"].z = 10
    rangle.delete_at(a)
  end
  for j in 0...16
    fp["p#{j}"] = Sprite.new(viewport)
    fp["p#{j}"].bitmap = pbBitmap("Graphics/Transitions/badgeParticle")
    fp["p#{j}"].ox = fp["p#{j}"].bitmap.width/2
    fp["p#{j}"].oy = fp["p#{j}"].bitmap.height/2
    fp["p#{j}"].opacity = 0
    fp["p#{j}"].x = viewport.rect.width/2
    fp["p#{j}"].y = viewport.rect.height/2
    fp["p#{j}"].z = 15
  end
  # handling of background
  fp["bg"] = Sprite.new(viewport)
  fp["bg"].bitmap = screen
  fp["bg"].blur_sprite(3)
  fp["bg"].bitmap.blt(0, 0, pbBitmap("Graphics/Transitions/badgeShade"), Rect.new(0,0,viewport.rect.width,viewport.rect.height))
  fp["eff"] = Sprite.new(viewport)
  fp["eff"].bitmap = pbBitmap("Graphics/Transitions/badgeEffect")
  fp["eff"].ox = fp["eff"].bitmap.width/2
  fp["eff"].oy = fp["eff"].bitmap.height/2
  fp["eff"].x = viewport.rect.width/2
  fp["eff"].y = viewport.rect.height/2
  fp["eff"].visible = $PokemonSystem.screensize < 2
  fp["text"] = Sprite.new(viewport)
  fp["text"].bitmap = Bitmap.new(viewport.rect.width,36)
  fp["text"].ox = fp["text"].bitmap.width/2
  fp["text"].oy = fp["text"].bitmap.height
  fp["text"].x = viewport.rect.width/2
  fp["text"].y = viewport.rect.height*0.9
  fp["text"].z = 45
  pbSetSystemFont(fp["text"].bitmap)
  pbDrawOutlineText(fp["text"].bitmap,0,0,fp["text"].bitmap.width,fp["text"].bitmap.height,FancyBadges::NAMES[badge_number], Color.white, Color.black, 1)
  # calculating badge dimensions
  isBack = false
  bmp = pbBitmap("Graphics/Transitions/getBadge#{badge_number}")
  height = bmp.height
  width = bmp.height
  width_side = bmp.width - width*2
  # front panel of badge
  front = Bitmap.new(width,height)
  front.blt(0,0,bmp,Rect.new(0,0,width,height))
  # back panel of badge
  back = Bitmap.new(width,height)
  back.blt(0,0,bmp,Rect.new(bmp.width-width,0,width,height))
  # side panel of badge
  side = Bitmap.new(width,height)
  side.blt(0,0,bmp,Rect.new(width,0,width_side,height))
  # extrudes the edges of the badge panels
  pointsF = [analyzeBitmap3D(front),analyzeBitmap3D(front,true)]
  pointsB = [analyzeBitmap3D(back),analyzeBitmap3D(back,true)]
  # handles badge sprite initialization
  badge_f = Sprite.new(viewport)
  badge_f.bitmap = Bitmap.new(width,height*1.25)
  badge_f.ox = badge_f.bitmap.width/2
  badge_f.oy = badge_f.bitmap.height/2
  badge_f.x = viewport.rect.width/2
  badge_f.y = viewport.rect.height/2
  badge_f.z = 55

  badge_s = Sprite.new(viewport)
  badge_s.bitmap = Bitmap.new(width,height*1.25)
  badge_s.ox = badge_s.bitmap.width/2
  badge_s.oy = badge_s.bitmap.height/2
  badge_s.x = viewport.rect.width/2
  badge_s.y = viewport.rect.height/2
  badge_s.z = 50

  temp = Bitmap.new(width,height*1.25)
  side_temp = Bitmap.new(width,height)
  offset = (temp.height - height)*0.25
  # misc variables required for calculations
  zoom_x = 1.0 # don't change
  zoom_y = 1.0 # don't change
  zoom_s = 0.9 # don't change
  speed = 0.75.delta_sub(false) # increase/decrease to speed up/down
  k = 1 # don't change
  m = 1 # don't change
  series = 0 # don't change
  reverse = false # don't change
  tone = -64 # controls 'shaders'
  # start of animation
  pbMEPlay("getBadge")
  for frame in 0...224
    # viewport flash
    viewport.color.alpha -= 5 if viewport.color.alpha > 0
    # rendering of the badge
    badge_f.bitmap.clear
    badge_s.bitmap.clear
    temp.clear
    side_temp.clear
    points = (isBack ? pointsB : pointsF)[reverse ? 1 : 0]
    ratio1 = splitGradient(1.0,zoom_y,width,reverse)
    ratio2 = splitGradient2(1.0,zoom_s,width_side,reverse)
    y2 = 0
    for y in 0...height
      w = width*zoom_x
      x = (width - w)*0.5
      x = x.floor
      z2 = 1.0 - zoom_x
      w2 = width_side*z2
      if !points[y].nil?
        for l in 0...points[y].length
          o = reverse ? (points[y][l]*zoom_x).floor : (points[y][l]*zoom_x).ceil
          x2 = x + o - (reverse ? w2.ceil : w2.ceil)
          x2 = (reverse ? x2.ceil : x2.ceil) + (reverse ? 0 : 2)
          w2 = w2.ceil
          side_temp.stretch_blt(Rect.new(x2,y,w2,1),side,Rect.new(0,y2,width_side,1))
        end
        y2 += 1
      end
    end
    for x in 0...width
      xs = (x/width.to_f)*width_side
      xs = ((width-1-x)/width.to_f)*width_side if reverse
      xs = xs.floor
      h = (side_temp.height*ratio1[x]*ratio2[xs]).ceil
      y = (side_temp.height - h)*0.5
      y = y.floor
      badge_s.bitmap.stretch_blt(Rect.new(x,y+offset,1,h),side_temp,Rect.new(x,0,1,side_temp.height))
    end
    for y in 0...height
      w = width*zoom_x
      z2 = 1.0 - zoom_x
      w2 = width_side*z2
      x = (width - w)*0.5 - (reverse ? w2 : 0).floor
      x = reverse ? x.ceil : x.floor
      temp.stretch_blt(Rect.new(x,y+offset,w,1),isBack ? back : front,Rect.new(0,y,width,1))
    end
    for x in 0...width
      h = temp.height*ratio1[x]
      y = (temp.height - h)*0.5
      y = y.floor
      badge_f.bitmap.stretch_blt(Rect.new(x,y,1,h),temp,Rect.new(x,0,1,temp.height))
    end
    zoom_x -= 0.050*k*speed
    zoom_y -= 0.025*k*speed
    zoom_s += 0.005*k*speed
    k *= -1 if zoom_x <= 0 || zoom_x >= 1
    isBack = !isBack if zoom_x <= 0
    reverse = !reverse if zoom_x <= 0 && k < 0
    series += 1 if zoom_x <= 0 || zoom_x >= 1
    if series > 1
      reverse = false
      series = 0
      zoom_x = 1
      zoom_y = 1
      zoom_s = 0.9
      k = 1
    end
    t1 = tone*(1 - zoom_x)
    badge_f.tone = Tone.new(t1,t1,t1)
    t2 = tone*(zoom_x)
    badge_s.tone = Tone.new(t2,t2,t2)
    # animation for rays
    for j in 0...8
      if fp["#{j}"].opacity == 0 && j<=(frame%128)/16 && frame < 200
        fp["#{j}"].opacity = 255
        fp["#{j}"].zoom_x = 0
        fp["#{j}"].zoom_y = 0
      end
      fp["#{j}"].opacity -= frame < 200 ? 4 : 12
      fp["#{j}"].zoom_x += 0.025
      fp["#{j}"].zoom_y += 0.025
    end
    # animation for particles
    for j in 0...16
      if fp["p#{j}"].opacity == 0 && j<=(frame%128)/8 && frame < 200
        fp["p#{j}"].opacity = 255
        fp["p#{j}"].oy = fp["p#{j}"].bitmap.height/2
        fp["p#{j}"].angle = rand(360)
        z = [0.8,0.5,0.3,0.8,0.6,0.4][rand(6)]
        fp["p#{j}"].zoom_x = z
        fp["p#{j}"].zoom_y = z
      end
      fp["p#{j}"].opacity -= frame < 200 ? 4 : 12
      fp["p#{j}"].oy += 4
    end
    if frame >= 200
      badge_s.opacity -= 12
      badge_s.zoom_x -= 0.02
      badge_s.zoom_y -= 0.02
      badge_f.opacity -= 12
      badge_f.zoom_x -= 0.02
      badge_f.zoom_y -= 0.02
      fp["eff"].opacity -= 12
      fp["bg"].opacity -= 12
      fp["text"].opacity -= 12
      fp["text"].zoom_x += 0.02
    end
    fp["eff"].angle += 2
    pbWait(0.02)
  end
  # disposal of all sprites
  badge_s.dispose
  badge_f.dispose
  pbDisposeSpriteHash(fp)
  viewport.dispose
end
#-------------------------------------------------------------------------------
