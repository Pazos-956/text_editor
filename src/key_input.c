#include <ctype.h>
#include <termios.h>
#include <unistd.h>
#include "lua.h"

static int key_input(lua_State *L){
    char c;
    if(read(STDIN_FILENO, &c, 1) == 1) {
        if(c == '\x1b') {
            char seq[3];
            if (read(STDIN_FILENO, &seq[0], 1) != 1){
                lua_pushnumber(L, c);
                lua_pushnumber(L, 0);
                return 2;
            }
            if (read(STDIN_FILENO, &seq[1], 1) != 1) {
                lua_pushnumber(L, c);
                lua_pushnumber(L, 0);
                return 2;
            }

            if (seq[0] == '[') {
                switch (seq[1]) {
                    case 'A':
                    case 'B':
                    case 'C':
                    case 'D':
                        lua_pushnumber(L, seq[1]);
                        lua_pushnumber(L, 10);
                        return 2;
                    default:
                        lua_pushnumber(L, seq[1]);
                        lua_pushnumber(L, -1);
                        return 2;
                }
            }
        }
        if (iscntrl(c)) {
            lua_pushnumber(L, c);
            lua_pushnumber(L, 1);
            return 2;
        }else {
            lua_pushnumber(L, c);
            lua_pushnumber(L, 0);
            return 2;
        }
    }
    return 0;
}

int luaopen_input(lua_State *L){
  lua_register(L, "key_input", key_input);
    return 1;
}

// gcc -shared -o input.so -fPIC key_input.c
