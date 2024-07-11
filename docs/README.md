# EDITOR DE TEXTO
En este documento intentaré explicar un poco el funcionamiento del editor que he hecho,
este editor es probablemente el peor codigo que vas a ver, ni se lua ni se como funciona
un editor, esto es un trabajo para ver como funciona un editor y para comprobar que efectivamente
lua no es el mejor lenguaje para esto. No añadiré más cosas al editor y faltan algunas cosas (scroll horizontal
por ejemplo). También hay algunos fallos, como que al moverse hacia abajo con el scroll vertical, en la última línea
se imprimen lineas incorrectas (esto es un error puramente gráfico).

Las referencias están al final del documento.
## Init
Para ejecutar el editor solo tienes que poner `lua init.lua` y seguido del fichero que quieras editar o crear, si no hay fichero creará newfile.txt.

El init.lua llama a `Draw_editor()`, que dibuja el editor en terminal, vacío o con texto dependiendo
de si abres o no un archivo existente. Despues llama a `Control_input()`, que se encarga de manejar las
entradas de teclado. Está envuelto en la función `pcall()` para que en caso de error se ejecute el
`os.execute()`, Esto es importante porque lo que hacen (tanto el de dentro como el de fuera)
es desactivar y activar unas flags del terminal mediante el comando `tty`. Estas flags son las que cambian entre el _"canonical mode"_
y el _"raw mode"_, además de facilitar ciertos aspectos de la escritura en terminal. Las flags son:

- ECHO: Printea cada tecla en la terminal, puede parecer raro desactivar esto, pero
echo también printea carácteres especiales como la tecla de borrar o Ctrl-c, por lo 
que es mejor desactivarlo y printear manualmente todo lo que escribamos. Es lo que usa sudo para la contraseña.
- ICANON: Es la flag del "canonical mode", por lo que al desactivarlo leeremos el input byte a byte
en lugar de linea a linea.
- ISIG: Activa o desactiva carácteres especiales como Ctrl-c, Ctrl-z y otros carácteres
para interrumpir el programa (hay que tener en cuenta que al quitarlo no podrás salir del programa
a no ser que asignes una tecla a ese propósito, con un break en el bucle por ejemplo.)
- IXON: Activa o desactiva las teclas de control de flujo, esto es que si por ejemplo
pulsas Ctrl-s, se dejará de pasar data a la terminal hasta que pulses Ctrl-q. Como no nos interesa
lo desactivamos.
- IEXTEN: Activa o desactiva carácteres especiales non-POSIX.
- ICRNL: Esto hace que (13, '\r') se lea como (10, '\n'), y se puede desactivar al quitar esta opción.
Esto hace que la tecla enter también se lea como (13, '\r'), ya que de normal produce (10, '\n').
- OPOST: La terminal traduce cada newline ("\n") en un return mas newline ("\r\n").
Esto es preferible desactivarlo y hacerlo de forma manual supongo, para tener más
control sobre el texto que se escribe, aunque habrá que ver si es necesario más adelante.
- BRKINT, INPCK, ISTRIP, CS8: Agrupo todas estas porque según la guía solo se desactivan
por costumbre, pero son flags que se usaban antiguamente y ya vienen desactivadas o ya 
no funcionan, por lo que no haría falta en un principio, yo no las voy a desactivar porque
luego ejecuto el comando para activar todas y hay algunas que tienen que estar desactivadas,
así me libro de algun error tonto de activar una que no debo.

## Globals
Aquí básicamente guardo variables globales que se usan en todo el documento. Igual no todas son necesarias
pero son las que tuve que usar para las soluciones a las que llegué para ciertos problemas.
Básicamente guardamos la posición del cursor (Cursor_x/Cursor_y), la última posición que tuvieron
Last_x(para las flechas verticales), un contador de carácteres para saber donde estoy en la piece table
(Char_count), el offset para dibujar por pantalla y tener scroll vertical(Row_offset),
el número de filas y columnas de la terminal para saber cuanto imprimir (Row/Col_screen), Ptable es la piece_table,
y por último Total_rows es una tabla donde guardo para cada linea el nº de carácteres que hay en ella.

## Insertar texto
### Input
Lo primero de todo es que tuve que hacer una función en c que lea el input y me pase tanto
el caracter como de que tipo es (control, letra o flecha), esto lo hice en c porque tenía problemas
para los carácteres que ocupan más de un byte como las flechas que son 3, 
ya que en lua tenía que leer de byte en byte. Este archivo hay que compilarlo en una librería dinámica,
con lo que podrás llamarla en lua como si fuera un paquete normal.

### Control del input
La función en c se llama en `Control_input()`, que es un bucle infinito, básicamente recibes el caracter y el tipo, y dependiendo
del tipo puedes insertarlo, salir del programa, borrar, usar las flechas, etc. Aquí tenemos el primer gran error,
y es que `string.char`en lua no funciona con carácteres de ASCII extendido, por lo que cualquier caracter
que no esté en el ASCII normal lo convierto en ñ para que vaya la tecla. Algunas cosas importantes son que siempre que
modifico el texto cambio la posición del cursor, char_count y Last_x, además debido a una flag que desactivamos antes,
si el caracter es un salto de línea (\n), se le añade un carriage return (\r\n) para que vaya al inicio
de la siguiente fila. Si se pulsa una flecha se manda a la función `move_cursor(key)`, que mueve la flecha manteniendo
la posición en caso de moverse entre filas con la flecha vertical. Por último al final del bucle se llama a `Refresh_screen()`,
que actualiza lo que se ve por pantalla.

## Estructura de datos
En [este archivo](Data_struct.md) explico las diferentes estructuras que se pueden usar, yo usé la piece table, sin embargo hay un par de cambios
con respecto a la estructura original. El principal es que se deberían almacenar strings enteros e ir dividiendolos o uniendolos segun sea necesario,
yo almaceno cada caracter en una posición de la tabla, por lo que siempre lo tengo dividido al mínimo.<br>
Las funciones principales de la estructura son `Insert()`, `Delete()` y `clean_table()`:
- clean_table: Esta es una función auxiliar llamada al final de las otras dos, pero muy importante, lo que hace es juntar las piezas que sean contiguas.
Esto es esencial ya que insert funciona caracter por caracter, lo que hace que se inserten muchas piezas new seguidas,
si no tuvieramos esta función la piece table crecería demasiado (notar que sigue creciendo mucho ya que al no guardar en un string
los carácteres necesitamos más entradas en la tabla si las posiciones en la tabla new no son continuas).

- Insert: Se le pasa el caracter a insertar, que lo mete en una nueva pieza, si el cursor se encuentra al principio
del archivo, se inserta de primero y se mueven el resto de piezas, si no, se llama a la función auxiliar
`find_one_piece()`, que busca en que pieza se encuentra el cursor y devuelve el numero de la pieza y la suma de los
carácteres de las piezas anteriores (para calcular la posición del cursor relativa en esa pieza). Una vez sabemos
en que pieza estamos y donde tenemos que dividirla, la separamos en dos piezas distintas e insertamos en el medio la pieza nueva.

- Delete: Llama a la función 'find_one_piece()` para saber la pieza en la que está el cursor, despues separa la pieza en dos
y a la primera le resta 1 al tamaño, lo que "borra" ese caracter.

Tanto en Insert como en Delete hay una condición especial para cuando se inserta o se borra un enter, ya que hay que cambiar más cosas
que al borrar o insertar un caracter normal.

Otras funciones relacionadas a la piece table que son importantes de mencionar son:
- Fill_rowfile: Esta función recorre la tabla y devuelve una tabla con un string por linea, para poder dibujarla por pantalla.
- Fill_original: Esta función lee el fichero que se le pasa como argumento al editor y lo escribe en la tabla que usamos como Original,
también inicia la tabla llamando a `start_ptable()`

## Dibujar en pantalla
A lo largo del código, y principalmente aqui, usamos [secuencias de escape VT100](#referencias).
No las voy a explicar pero todas suelen empezar por `\x1b[` .

Tan pronto inicias el programa se llama a `Draw_editor()`, que imprime el editor vacío si no se le pasa ningún parámetro
o llama a `draw_file()` para que dibuje el fichero que se ha abierto (si no existe draw_file() dibuja el editor vacío).

`Draw_file()` llama a `Fill_rowfile()`, de donde saca el archivo por lineas, y con Row_offset calcula desde que linea hasta
que linea debe dibujar en pantalla. Si el archivo acaba antes de terminar la pantalla del editor, imprime ~.

Por último la función `Refresh_screen()` se llama en el bucle que controla el input, esta función llama a las funciones
`editor_scroll()`, que calcula el offset para el scroll vertical, y `draw_file()`, que como hemos explicado antes imprime el archivo
por pantalla.


# Referencias
#### Editor de texto:
- La idea de hacer el editor viene de [este artículo sobre proyectos.](https://austinhenley.com/blog/challengingprojects.html)
- [Secuencias de escape VT100](https://en.wikipedia.org/wiki/VT100)
- [Hacer un editor en C](https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html)
#### Estructuras de datos:
- [Piece table](https://mathspp.com/blog/til/piece-table-data-structure)
- [Foro original sobre estructuras de datos.](https://www.averylaird.com/programming/the%20text%20editor/2017/09/30/the-piece-table)
- [Paper de Charles Crowley comparando varias estructuras de datos.](https://www.cs.unm.edu/~crowley/papers/sds.pdf)
- Wikipedia:
    - [rope.](https://en.wikipedia.org/wiki/Rope_(data_structure))
    - [Gap Buffer.](https://en.wikipedia.org/wiki/Gap_buffer)
