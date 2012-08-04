extern "C" void* mmxProc(void*, int, int, float, float, float);

#include <stdlib.h>
#include "SDL.h"
#include "SDL_image.h"

#define WIDTH  1366
#define HEIGHT 768
#define BITS   32
#define COLOR  0x006123af
#define IMAGENAME "sample.png"

SDL_Surface *screen;
int a[WIDTH][HEIGHT];
int temp[WIDTH][HEIGHT];

int mmxCall(float prop_r, float prop_g, float prop_b) {
	for(int i = 0; i < WIDTH; i++)
		for(int j = 0; j < HEIGHT; j++)
			temp[i][j] = a[i][j];
	mmxProc(temp, WIDTH, HEIGHT, prop_r, prop_g, prop_b);
	for(int i = 0; i < WIDTH; i++) 
		for(int j = 0; j < HEIGHT; j++)
			a[i][j] = temp[i][j];
	return 0;
}

void putpixel(int x, int y, int color) {
    unsigned int *ptr = (unsigned int*)screen->pixels;
    int lineoffset = y * (screen->pitch / 4);
    ptr[lineoffset + x] = color;
}

void init() {
	SDL_Surface *temp;
	if(!(temp = IMG_Load(IMAGENAME))) {
		fprintf(stderr, "IMG_Load: %s\n", IMG_GetError());
		exit(1);
	}
	temp = SDL_ConvertSurface(temp, screen->format, SDL_HWSURFACE);

	unsigned int *ptr = (unsigned int*)temp->pixels;
	int start_i = (screen->w>temp->w)?(screen->w-temp->w)/2:0;
	int start_j = (screen->h>temp->h)?(screen->h-temp->h)/2:0;
	for (int i=0; i<temp->w; i++)
		for (int j=0; j<temp->h; j++)
		{
			int lineoffset = j * (temp->pitch / 4);
			a[i+start_i][j+start_j] = ptr[lineoffset + i];
		}
	SDL_FreeSurface(temp);
}

void render() {   
    if (SDL_LockSurface(screen) < 0) 
        return;
    int tick = SDL_GetTicks();

	for (int i=0; i<WIDTH; i++)
		for (int j=0; j<HEIGHT; j++)
		{
			putpixel(i, j, a[i][j]);
		}
    if (SDL_MUSTLOCK(screen)) 
        SDL_UnlockSurface(screen);
    SDL_UpdateRect(screen, 0, 0, WIDTH, HEIGHT);    
}


int main(int argc, char *argv[]) {
    if ( SDL_Init(SDL_INIT_VIDEO) < 0 ) 
    {
        fprintf(stderr, "Unable to init SDL: %s\n", SDL_GetError());
        exit(1);
    }

    atexit(SDL_Quit);
    
    screen = SDL_SetVideoMode(WIDTH, HEIGHT, BITS, /* SDL_FULLSCREEN| */ SDL_HWSURFACE);
    
    if(screen == NULL) 
    {
        fprintf(stderr, "Unable to set %dx%d video: %s\n", WIDTH, HEIGHT, SDL_GetError());
        exit(1);
    }

	init();
	
    while (true)
    {
        render();

        SDL_Event event;
        while (SDL_PollEvent(&event)) 
        {
            switch (event.type) 
            {
            case SDL_KEYDOWN:
                break;
            case SDL_KEYUP:
				if (event.key.keysym.sym == SDLK_ESCAPE) {
					SDL_SaveBMP(screen, "result.bmp");
                    return 0;
				}
				else if (event.key.keysym.sym == SDLK_1)
					mmxCall(1.0, 1.0, 1.0);
				else if (event.key.keysym.sym == SDLK_2)
					mmxCall(1.0, 0, 0);
				else if (event.key.keysym.sym == SDLK_3)
					mmxCall(0, 1.0, 0);
				else if (event.key.keysym.sym == SDLK_4)
					mmxCall(0, 0, 1.0);
				else if (event.key.keysym.sym == SDLK_5)
					mmxCall(1.0, 1.0, 0);
				else if (event.key.keysym.sym == SDLK_6)
					mmxCall(1.0, 0, 1.0);
				else if (event.key.keysym.sym == SDLK_7)
					mmxCall(0, 1.0, 1.0);
				else if (event.key.keysym.sym == SDLK_8)
					mmxCall(0.5, 0.5, 0.5);
				else if (event.key.keysym.sym == SDLK_TAB)
					init();
                break;
            case SDL_QUIT:
                return(0);
            }
        }
    }
    return 0;
}
