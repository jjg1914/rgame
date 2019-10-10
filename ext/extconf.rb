require "mkmf"

find_header("SDL.h", "/usr/local/include/SDL2") or abort "Can't find the SDL.h header"
find_library("SDL2", "SDL_Init") or abort ("Can't find the SDL library")
find_library("SDL2_ttf", "TTF_Init") or abort ("Can't find the SDL_ttf library")

create_makefile("SDL_FontCache/SDL_FontCache", "SDL_FontCache")
