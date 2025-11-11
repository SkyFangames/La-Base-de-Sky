###Script de Libro creado por Nyaruko###

#Instrucciones: Crear una constante (lo de los ejemplos LIBRO0 y LIBRO1, en Mayusculas)
#Y seguir el ejemplo de como están lo que serían las páginas, teniendo el límite 
#de 165 caracteres por página. Luego añadir esa constante a la lista de LIBROS.
#Para llamar al script tienes que poner en un evento BookScene.new.pbBook(x), siendo
#x la posición del libro que se quiera mostrar, teniendo en cuenta que la
#posicion 1 es 0. Por ejemplo para leer el primer libro se tendría que
#poner BookScene.new.pbBook(0)


#165 caracteres de media
LIBRO0 = [
_INTL("Bitácora Policial - Caso Acadeimia Eón"),
_INTL("Querida hija mia: Te dejo esta pequeña bitácora para que puedas emprender tu carrera como policía, al igual que mi padre me la entrego a mí cuando comencé la mía."),
_INTL("Espero que te sea de ayuda en tu camino para lograr marcar la diferencia en el mundo. Recuerda siempre hacer lo correcto y nunca rendirte ante las adversidades."),
_INTL("Página 3."),
_INTL("Página 4."),
_INTL("Página 5."),
_INTL("Página 6."),
_INTL("Página 7."),
_INTL("Página 8."),
_INTL("Página 9."),
_INTL("Página 10."),
]

LIBRO1 = [
_INTL("LIBRO DE EJEMPLO 2"),
_INTL("Página 1 de 5"),
_INTL("Página 2 de 5"),
_INTL("Página 3 de 5"),
_INTL("Página 4 de 5"),
_INTL("Página 5 de 5"),
]


LIBROS = [LIBRO0, LIBRO1] # PONER AQUÍ MÁS LIBROS SEGÚN LOS CREES

class BookScene
  def pbBook(id)
    viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    viewport.z=99998
    #256 x 286
    #116x58
    @pagev=Viewport.new(116,58,256,286)
    @pagev.z = 99999
    @bitpage=BitmapSprite.new(256,286,@pagev)
    @libros = LIBROS
    @libro = @libros[id]
    select = 0
    @page = 0
    @sprites = {}
    @sprites["libro"]=IconSprite.new(0,0,viewport)
    @sprites["libro"].setBitmap("Graphics/Pictures/Book/0")
    @sprites["libro"].x =0
    @sprites["libro"].y =0
    loop do
      texto
      Graphics.update
      Input.update     
      if Input.trigger?(Input::BACK)
          pbSEPlay("select")
          pbFadeOutAndHide(@sprites){pbUpdateSpriteHash(@sprites)}
          viewport.dispose if viewport
          @pagev.dispose
          break
        end
        if Input.trigger?(Input::RIGHT) && @page < @libro.size - 1
          @pagev.visible = false
          pbSEPlay("select")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/1")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/2")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/3")
          pbWait(2)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/4")
          pbWait(2)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/5")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/6")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/7")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/8")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/9")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/10")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/0")
          @page += 1
          @pagev.visible = true
        end
        if Input.trigger?(Input::LEFT) && @page > 0
          pbSEPlay("select")
          @pagev.visible = false
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/10")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/9")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/8")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/7")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/6")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/5")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/4")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/3")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/2")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/1")
          pbWait(1)
          @sprites["libro"].setBitmap("Graphics/Pictures/Book/0")
          @page -= 1
          @pagev.visible = true
        end 
      end
  end
  
  def texto
    pbSetSystemFont(@bitpage.bitmap)
    overlay = @bitpage.bitmap
    overlay.clear
    drawTextEx(@bitpage.bitmap,0,10,256,10,@libro[@page],Color.new(40,40,40),Color.new(120,120,120)) 
  end
end  