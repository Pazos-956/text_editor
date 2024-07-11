# EDITOR DE TEXTO

Este es el documento donde iré explicando lo que hago cada día de trabajo en el
desarrollo de un editor de texto básico en lua. La idea viene de [este artículo sobre proyectos.](https://austinhenley.com/blog/challengingprojects.html)

La idea es hacer un editor de texto básico en cli y aprender su funcionamiento y cosas como
estructuras de datos, como funciona el cursor, puede que también añada las opciones
de undo/redo y word wrapping, además de implementar una GUI si decido probar a implementar librerías de c en el código, aunque no lo veo probable.
# DIA 1
## Insertar texto
Basándome en la guía de [viewsourcecode,](https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html)
lo primero que debo intentar es insertar texto en la terminal, esto puede parecer fácil
si piensas en insertar un string, pero en un editor de texto debe actualizarse caracter
a caracter, y las funciones de inserción normalmente solo insertan cuando tecleas Enter.
- Al parecer la terminal usa algo llamado "canonical mode", en este modo, el input
escrito en la terminal solo se envía cuando el usuario teclea Enter, por lo que 
aunque soluciones el primer problema, seguirás sin poder mandar el texto letra a letra.

Para guardar la entrada estandar se usa `io.stdin:read()`, la solución es poner `io.stdin:read(1)` dentro
de un bucle infinito, lo que hace que se coja solo un caracter y la función read devuelva
ese valor, al estar en un bucle infinito tan pronto como devuelve el caracter vuelve a pedir
otro, lo que hace la ilusión de poder escribir de forma infinita mientras recibes cada letra.

El segundo problema también es facil pero algo más complicado, en c existe una llamada
que te permite cambiar las flags de la terminal para cambiar de "canonical mode" a 
"raw mode", que es el modo que envía el input tan pronto se escribe, pero lua no tiene
esa librería, y no me apetece mezclarla con c porque tampoco se como funciona la librería
que tengo que usar, por lo que una buena alternativa es la función `os.execute()`.
Esta función permite ejecutar comandos, y existe un comando llamado stty que 
nos permite desactivar ciertas cualidades de la terminal poniendo un guion delante 
(que por cierto tenemos que volver a activar SIEMPRE al salir del programa).<br>

# DIA 2
### Dibujar la pantalla.

Hay varios problems, el primero es que resulta que io.read(1) no sirve para coger el input
del teclado porque hay teclas demasiado grandes, como las flechas o algunos caracters especiales.
Esto es un problema evidentemente, por lo que igual tengo que hacer una integración con c.

Además de eso he hecho la función para dibujar el editor en pantalla.
Usa principalmente secuencias de escape de [VT100](https://en.wikipedia.org/wiki/VT100)
para limpiar la pantalla, mover el cursor etc. Otra cosa interesante es la función
io.popen(), esta hace lo mismo que io.execute(), pero devuelve un fichero temporal (handler)
que contiene el resultado del comando, que luego puedes leer con handler:read(),
lo uso para saber el tamaño de la ventana del terminal.

# DIA 3
### Problemas con input 2, ahora es personal
Llevo casi todo el día intentando hacer una función en c que se pueda usar en lua,
lo conseguí pero no gracias a como está explicado en la documentación xdd, pero ahora
no se imprime lo que escribo hasta que salgo del programa, no se por que pero creo que 
es por el io.stdout:write(), probar a no usar el io.stdout

# DIA 4
Pues después de estar horas intentando que lo que la función de c captura se escriba a
la vez por la salida estandar o por cualquier salida, no funciona hasta que salgo del programa,
por lo que he quitado esa función y he hecho una función en lua que mas o menos 
captura lo que necesito segun su codigo ascii, el problema es que hay que ir adaptando el
código ascii dependiendo de lo que quieres atrapar, lo que no creo que sea bueno pero 
es lo que hay por ahora a no ser que encuentre una mejor solución.
Aun así parece que al escribir en el stdout, ya automáticamente sabe cuando es una
flecha, un carácter especial o un control, por lo que no haría falta ver las excepciones
creo. Para la proxima me fijo mas y no hago un cristo cuando no lo necesito xd.

# DIA 5 
Pues hice bien poco, empecé con la estructura de datos, pero no tengo muy claro como hacerlo.
Por ahora solo hice el array que guarda byte a byte lo que se escribe, el buffer "original", y una
forma básica del buffer "new", aunque tendré que cambiarlo probablemente para cuando
tenga que llamarlo para guardar los bytes en el.

# DIA 6
A la noche cree el fichero globals para guardar información relevante para el editor,
mañana por la mañana lo creo todo y sigo en este dia.<br>
He vuelto a cambiar la forma de coger el input a la función en c, ahora funciona gracias al
flush, y he cambiado varias cosas para que funcionen con esa funcion en vez de la anterior.
Tambien he añadido las globales y que coja la posicion del cursor. Falta cambiar el draw_screen
para que si le pasas un archivo este se escriba, y si no escriba la pantalla vacía.

# DIA 7 
Estuve intentando que escriba un fichero al iniciar, pero acabe haciendo un cristo, tengo que ver 
que carajo hago ahi para arreglar eso porque ni yo entiendo lo que está pasando.<br>
Bueno, limpie un poco eso pero parece que no coge bien el arg, aunque si que lo imprime directamente
asi que tiene que ser un problema del read.<br>
POR EL AMOR DE DIOS NO INICIAR UNA VARIABLE DENTRO DE UN BUCLE, QUE SE REINICIA.

# DIA 8
Arregle algunos fallos, puse a funcionar las flechas y mejoré el seguimiento del cursor, que era nulo.
También guardé el archivo original en su tabla correspondiente en data_structures, mañana haré para guardar
lo que escriba, y puede que también la piece table. Tengo muchos problemas por arreglar y muchos que me voy encontrando,
esto es un desastre xd.
# DIA 9
Probando a hacer la piece table, que es lo unico que queda, tuve que hacer una variable que lleve la cuenta de los char que llevo en el archivo
para poder dividir bien todo, y para más información de la piece table tengo esta [pagina](https://mathspp.com/blog/til/piece-table-data-structure)

# DIA 10
Pues me quiero ir a dormir asi que no voy a explicar una mierda xd pero basicamente ya funciona insertar en la piece table.
IMPORTANTE: SI A UNA VARIABLE LE DAS DE VALOR UNA TABLA, LOS CAMBIOS SE HACEN EN LAS DOS no se cuanto tiempo perdi con esa mierda.

# DIA 11, 12, 13
Bueno, creo que se me olvidaron un par de dias asi que pongo así ya que terminé, mantener el cursor con el cambio de tamaño de las lineas fue horrible,
y hay muchas cosas mal, pero creo que voy a dejarlo por aquí ya que es mínimamente funcional.
