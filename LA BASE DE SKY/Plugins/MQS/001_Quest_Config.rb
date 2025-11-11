#===============================================================================
# Modern Questing System + UI
# ¡Si te gustan las misiones, este es el recurso para ti!
#===============================================================================
# Implementación original por mej71.
# Actualizado para v17.2 y v18/18.1 por derFischae
# Muy editado para v19/19.1 por ThatWelshOne_
# Algunos componentes de la interfaz de usuario tomados prestados (con permiso) de Easy Questing Interface de Marin
# Adaptado a v21.1 con las aportaciones de dpertierra
# Ideas y correción de errores por DarmanÍñigo
# Traducción, adaptación al español y nuevas mejoras por Turi
#
#===============================================================================
# Cosas que puedes personalizar sin editar los propios scripts
#===============================================================================

# Si está marcado verdadero (true), incluye una página de misiones fallidas en la interfaz de usuario.
# Márcalo como falso (false) si no quieres tener misiones en las que puedas fallar
SHOW_FAILED_QUESTS = true

# Opción para ordenar las misiones por historia (parámetro "story") y después por el momento en que se empezó.
SORT_STORY = true

# Opción para ordenar las misiones por su parámatro "id". Primero es necesario desactivar la antetior.
SORT_ID = true

# Opción para mostrar el registro de tiempo de la misión en la interfaz de usuario.
TIME_VISIBLE = true

# Nombre del archivo en Audio/SE que se reproduce cuando se activa/avanza a una nueva etapa de una misión
QUEST_JINGLE = "Mining found all.ogg"

# Nombre del archivo en Audio/SE que se reproduce cuando se  completa una misión
QUEST_DONE = "Mining reveal full.ogg"

# Nombre del archivo en Audio/SE que se reproduce cuando se falla una misión
QUEST_FAIL = "GUI sel buzzer.ogg"

# Opción para acceder a la interfaz de misiones desde el menú de pausa
PAUSE_MENU = true

# Opción para implementar el menú de misiones como objeto clave (Libro de Misiones)
KEY_ITEM = true

#===============================================================================
# Método de utilidad para configurar colores.
#===============================================================================

# Convertidor de colores en Hex a 15-bit: http://www.budmelvin.com/dev/15bitconverter.html
# Agrega tus propios colores aquí
def colorQuest(color)
  color = color.downcase if color
  return "7DC076EF" if color == "azul"
  return "089D5EBF" if color == "rojo"
  return "26CC4B56" if color == "verde"
  return "6F697395" if color == "cian"
  return "5CFA729D" if color == "magenta"
  return "135D47BF" if color == "amarillo"
  return "56946F5A" if color == "gris"
  return "7FDE6B39" if color == "blanco"
  return "751272B7" if color == "morado"
  return "0E7F4F3F" if color == "naranja"
  return "2D4A5694" # Devuelve el color gris oscuro predeterminado si no corresponde con las demás opciones.
end
