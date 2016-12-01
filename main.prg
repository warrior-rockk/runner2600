// ========================================================================
//  Runner2600
//  Concurso "Gana tu avatar guay" juegos tipo Atari 2600
//  Warcom Soft. 
//  30/11/16
// ========================================================================

import "mod_key";
import "mod_map";
import "mod_video";
import "mod_text";
import "mod_scroll";
import "Mod_proc";
import "mod_sound";
import "Mod_screen";
import "Mod_draw";
import "Mod_grproc";
import "Mod_rand";
import "mod_file"; 
import "mod_math";
import "mod_say";
import "mod_debug";
import "mod_string";
import "mod_timers";
import "mod_time";
import "mod_mem";
import "mod_joy";
import "mod_wm";

//Modos funcion colCheckAABB
#define BOTHAXIS			0					//Ambos ejes
#define HORIZONTALAXIS		1					//Eje Horizontal
#define VERTICALAXIS		2					//Eje Vertical
#define INFOONLY			3                   //Solo informacion de colision

//Direccion colision
#define NOCOL		0
#define COLUP		1
#define COLDOWN		2
#define COLIZQ		3
#define COLDER   	4
#define COLCENTER   5

//Modos de la funcion animacion
#define ANIM_LOOP	0
#define ANIM_ONCE   1

//estados game
#define SPLASH_ST   0
#define RESET_ST	1
#define PLAY_ST		2
#define GAMEOVER_ST	3

//estados player
#define IDLE_ST 0
#define RUN_ST	1
#define JUMP_ST	2
#define DEAD_ST	3

//colores
#define SKY_COLOR 		rgb(0,92,92)
#define MISSILE_COLOR 	rgb(88,176,108)
#define WORLD_COLOR_R 	220
#define WORLD_COLOR_G 	192
#define WORLD_COLOR_B 	132

Type _entityPublicData
	float vX			= 0;     	//Velocidad X
	float vY			= 0;     	//Velocidad Y
	float fX			= 0;		//Posicion x coma flotante
	float fY			= 0;		//Posicion y coma flotante
	int   alto			= 0;   		//Altura en pixeles del proceso
	int   ancho			= 0;   		//Ancho en pixeles del proceso
	int   axisAlign     = 0;		//Alineacion del eje del grafico respecto caja colision
	int   state 		= 0;   		//Estado de la entidad
	int   prevState     = 0;		//Estado anterior
	int  props			= 0;		//Propiedades de la entidad
	int frameCount;					//Contador frames animacion	
end;

//constantes
Const
	cResX = 160;
	cResY = 110;
	cVelX = 1;
	cScrollX = 3;
	cMinSpace = 20;
	cMaxSpace = 100;
	cMinH     = 10;
	cMaxH     = 50;
	cMinW     = 12;
	cMaxW     = 50;
	cMaxWalls = 10;
	cMinMissileY = 30;
	cMaxMissileY = 80;
	cMinMissileW = 5;
	cMaxMissileW = 15;
end;

//globales
global
	gVelX = cVelX;
	gScrollX = cScrollX;
	struct wall[cMaxWalls] 
		int x;
		int y;
		int w;
		int h;
		int dw;
		int memBox = false;
	end;
	int wallNum=0;
	int score = 0;
	int difficulty = 0;
	//sound
	int sndJump;
	int sndExplosion;
	int sndMusic;
	int sndBeep;
	int sndLaser;
end;

//declaraciones
Declare Process entity()
public
	_entityPublicData this;			//datos publicos de entidad
end
end

Declare Process player1()
public
	_entityPublicData this;			//datos publicos de entidad
end
end

Declare Process missile2()
public
	_entityPublicData this;			//datos publicos de entidad
end
end

//gameLoop
process main()
private
	int i;
	string strScore = 0;
	entity idActor;
	int gameState = SPLASH_ST;
	int idFont;
	int flickering = 0;
	int skyDw[4];
	int iniSky = 17;
begin
	Scale_resolution = "0" + cResX*2 + "0" + CResY*2;
	set_mode(cResX,120,16);
	set_fps(60,0);
    define_region(1,0,10,cResX,110);
	region=1;
	//pintamos fondo
	map_clear(0,0,SKY_COLOR);
	drawing_z(255);
	drawing_color(SKY_COLOR+4226);
	skyDw[0] = draw_box(0,iniSky,cResX,iniSky+2);
	skyDw[1] = draw_box(0,iniSky+4,cResX,iniSky+6);
	skyDw[2] = draw_box(0,iniSky+8,cResX,iniSky+30);
	drawing_color(SKY_COLOR+(4226*2));
	skyDw[3] = draw_box(0,iniSky+2,cResX,iniSky+4);
	skyDw[4] = draw_box(0,iniSky+6,cResX,iniSky+8);
	
	//carga recursos
	idFont 			= load_fnt("fuente.fnt");
	sndJump 		= load_wav("jump.ogg");
	sndExplosion 	= load_wav("explosion.ogg");
	sndMusic		= load_song("music.ogg");
	sndBeep			= load_wav("beep.ogg");
	sndLaser		= load_wav("laser.ogg");
	
	misile1();
	
	loop
		switch (gameState)
			case SPLASH_ST:
				if (key(_enter))	
					play_wav(sndBeep,0,1);
					gameState = RESET_ST;
				end;
				if (key(_esc))
					exit("",0);
				end;
			end;
			case RESET_ST:
				let_me_alone();
				delete_draw(0);
				delete_text(all_text);
				for (i=0;i<wallNum;i++)
					wall[i].memBox = false;
				end;
				score = 0;
				difficulty = 0;
				gVelX = cVelX;
				gScrollX = cScrollX;
				write_var(idFont,10,10,0,strScore);
				misile1();
				idActor = player1();
				play_song(sndMusic,0);
				//pintamos fondo
				map_clear(0,0,SKY_COLOR);
				drawing_z(255);
				drawing_color(SKY_COLOR+4226);
				skyDw[0] = draw_box(0,iniSky,cResX,iniSky+2);
				skyDw[1] = draw_box(0,iniSky+4,cResX,iniSky+6);
				skyDw[2] = draw_box(0,iniSky+8,cResX,iniSky+30);
				drawing_color(SKY_COLOR+(4226*2));
				skyDw[3] = draw_box(0,iniSky+2,cResX,iniSky+4);
				skyDw[4] = draw_box(0,iniSky+6,cResX,iniSky+8);
				gameState = PLAY_ST;
			end;
			case PLAY_ST:
			
				//Convertimos la puntuacion a string formato de 8 digitos
				int2String(score,&strScore,8);
				
				//cada 1000 puntos, sube la dificultad
				if (score % 1000 == 0)
					gScrollX == 1 ? gVelX++ : gScrollX--;	
					difficulty++;
				end;
				
				//chequea la muerte del player
				if (idActor.this.state == DEAD_ST)
					gameState = GAMEOVER_ST;
				end;
				
				//reset
				if (key(_r))
					gameState = RESET_ST;					
				end;				
				
			end;
			case GAMEOVER_ST:
				stop_song();
				play_wav(sndExplosion,0,1);
				signal(all_process,s_freeze);
				for (i=0;i<5;i++)
					delete_draw(skyDw[i]);
				end;
				while (flickering < 5)
					map_clear(0,0,rgb(255,0,0));
					wait(10);
					map_clear(0,0,rgb(255,255,0));
					wait(10);
					flickering++;
				end;
				flickering = 0;
				//pintamos fondo
				map_clear(0,0,SKY_COLOR);
				drawing_z(255);
				drawing_color(SKY_COLOR+4226);
				skyDw[0] = draw_box(0,iniSky,cResX,iniSky+2);
				skyDw[1] = draw_box(0,iniSky+4,cResX,iniSky+6);
				skyDw[2] = draw_box(0,iniSky+8,cResX,iniSky+30);
				drawing_color(SKY_COLOR+(4226*2));
				skyDw[3] = draw_box(0,iniSky+2,cResX,iniSky+4);
				skyDw[4] = draw_box(0,iniSky+6,cResX,iniSky+8);
				wait(50);
				let_me_alone();
				delete_draw(0);
				delete_text(all_text);
				for (i=0;i<wallNum;i++)
					wall[i].memBox = false;
				end;
				write_var(idFont,10,10,0,strScore);
				//pintamos fondo
				map_clear(0,0,SKY_COLOR);
				drawing_z(255);
				drawing_color(SKY_COLOR+4226);
				skyDw[0] = draw_box(0,iniSky,cResX,iniSky+2);
				skyDw[1] = draw_box(0,iniSky+4,cResX,iniSky+6);
				skyDw[2] = draw_box(0,iniSky+8,cResX,iniSky+30);
				drawing_color(SKY_COLOR+(4226*2));
				skyDw[3] = draw_box(0,iniSky+2,cResX,iniSky+4);
				skyDw[4] = draw_box(0,iniSky+6,cResX,iniSky+8);
				gVelX = cVelX;
				gScrollX = cScrollX;
				difficulty = 0;
				misile1();
				gameState = SPLASH_ST;
			end;
		end;
				
		frame;
	end;
end;

//proceso jugador
process player1()
private
	float grav = 0.4;
	byte grounded = false;
	int	  dir;					
	int wallCheck = 0;
	byte hurt = false;
	byte memButtonJump = false;
begin
load_fpg("actor.fpg");
graph = 1;
x = 8;
y = 16;
this.ancho = 11;
this.alto = 14;
this.fX = x;
this.fY = y;
this.state = IDLE_ST;
region = 1;
loop
	//movimiento
	if (key(_right) && this.vX < 2)
		this.vX += 0.2;
		this.state = RUN_ST;
	end;
	if (key(_left) && this.vX > -2)
		this.vX -= 0.2;
		this.state = RUN_ST;
	end;
	if (!key(_right) && !key(_left))
		this.vX *= 0.8;
		this.state = 0;
	end;
	if (key(_up) )
		if (!memButtonJump)
			if (grounded)
				this.vY += -4;
				play_wav(sndJump,0,2);
			else
				this.vY += (this.vY*0.1);
			end;
		end;
	else
		memButtonJump = !grounded;		
	end;
	
	//gravedad 
	this.vY += grav;
	grounded = false;
		
	//colisiones con mundo
	for (wallCheck=0;wallCheck<wallNum;wallCheck++)
					
		//tratamos las colisiones separadas por ejes
		//para poder andar sobre varios procesos corrigiendo la y
		
		//colisiones verticales con procesos
		dir = colCheckAABB(id,wall[wallCheck].x,wall[wallCheck].y,wall[wallCheck].w,wall[wallCheck].h,VERTICALAXIS);
				
		//aplicamos la direccion de la colision
		applyDirCollision(ID,dir,&grounded);
		
		//colisiones horizontales con procesos
		dir = colCheckAABB(id,wall[wallCheck].x,wall[wallCheck].y,wall[wallCheck].w,wall[wallCheck].h,HORIZONTALAXIS);
		
		//aplicamos la direccion de la colision
		applyDirCollision(ID,dir,&grounded);
		
	end;
	
	//colsiones con misile2
	if (exists(TYPE missile2))
		//colisiones verticales con procesos
		dir = colCheckProcess(id,get_id(TYPE missile2),INFOONLY);
				
		if (dir!=NOCOL)
			hurt = true;
		end;
		
	end;
	
	//Actualizar velocidades
	if (grounded)
		this.vY = 0;
	else
		this.state = JUMP_ST;
	end;
	
	this.fX += this.vX;
	this.fY += this.vY;
	
	//limites pantalla
	if (this.fX > cResX)
		this.fX = cResX;
	end;
	if (this.fX < 0)
		if (dir == NOCOL)
			this.fX = 0;
		else
			hurt = true;
		end;
	end;
	
	//actualizar posicion float-int
	positionToInt(id);
	
	//flags y estados
	if (this.vX > 0)
		flags = 0;
	elseif (this.vX < 0)
		flags = 1;
	end;
	
	//muerte
	if (y > cResY+20 || hurt)
		this.state = DEAD_ST;
	end;
	
	this.prevState = this.state;
	
	//animaciones
	switch(this.state)
		case IDLE_ST:
			graph = 1;
		end;
		case RUN_ST:
			wgeAnimate(2, 5, 10,ANIM_LOOP);		
		end;
		case JUMP_ST:
			graph = 3;
		end;
	end;
		
	frame;
end;
end;

//proceso world
process misile1()
private
	int memBox;
	int i;
	int framecount=0;
begin
region = 1;
rand_seed(time());
drawing_color(rgb(WORLD_COLOR_R-(difficulty*16),WORLD_COLOR_G-(difficulty*16),WORLD_COLOR_B-(difficulty*16)));

//Creamos los obstaculos iniciales
wallNum=0;

wall[wallNum].w = cMaxW;
wall[wallNum].h = rand(cMinH,cMaxH);
wall[wallNum].x = 0+ (wall[wallNum].w>>1);//cResX + (wall[wallNum].w>>1);
wall[wallNum].y = cResY - (wall[wallNum].h>>1);
wall[wallNum].dw = draw_box(wall[wallNum].x-(wall[wallNum].w>>1),wall[wallNum].y-(wall[wallNum].h>>1),wall[wallNum].x+(wall[wallNum].w>>1),wall[wallNum].y+(wall[wallNum].h>>1));
wallNum++;

wall[wallNum].w = rand(cMinW,cMaxW);
wall[wallNum].h = rand(cMinH,cMaxH);
wall[wallNum].x = 100+ (wall[wallNum].w>>1);//cResX + (wall[wallNum].w>>1);
wall[wallNum].y = cResY - (wall[wallNum].h>>1);
wall[wallNum].dw = draw_box(wall[wallNum].x-(wall[wallNum].w>>1),wall[wallNum].y-(wall[wallNum].h>>1),wall[wallNum].x+(wall[wallNum].w>>1),wall[wallNum].y+(wall[wallNum].h>>1));
wallNum++;

wall[wallNum].w = rand(cMinW,cMaxW);
wall[wallNum].h = rand(cMinH,cMaxH);
wall[wallNum].x = 200+ (wall[wallNum].w>>1);//cResX + (wall[wallNum].w>>1);
wall[wallNum].y = cResY - (wall[wallNum].h>>1);
wall[wallNum].dw = draw_box(wall[wallNum].x-(wall[wallNum].w>>1),wall[wallNum].y-(wall[wallNum].h>>1),wall[wallNum].x+(wall[wallNum].w>>1),wall[wallNum].y+(wall[wallNum].h>>1));
wallNum++;

//bucle generacion obstaculos aleatorios
loop
	drawing_color(rgb(WORLD_COLOR_R-(difficulty*16),WORLD_COLOR_G-(difficulty*16),WORLD_COLOR_B-(difficulty*16)));
		
	if (frameCount % gScrollX == 0)
		for (i=0;i<wallNum;i++)
			wall[i].x -= gVelX;
			move_draw(wall[i].dw,wall[i].x-(wall[i].w>>1),wall[i].y-(wall[i].h>>1));
			
			if (not wall[i].memBox && wallNum<cMaxWalls)
				if ((wall[i].x+ (wall[i].w>>1))<=(cResX-rand(cMinSpace,cMaxSpace)))
					wall[wallNum].w = rand(cMinW,cMaxW);
					wall[wallNum].h = rand(cMinH,cMaxH);
					wall[wallNum].x = cResX + (wall[wallNum].w>>1);
					wall[wallNum].y = cResY - (wall[wallNum].h>>1);
					wall[wallNum].dw = draw_box(wall[wallNum].x-(wall[wallNum].w>>1),wall[wallNum].y-(wall[wallNum].h>>1),wall[wallNum].x+(wall[wallNum].w>>1),wall[wallNum].y+(wall[wallNum].h>>1));
					wallNum++;				
					wall[i].memBox = true;
				end;
			end;
			
			if (wall[i].x+ wall[i].w <= 0)
				delete_draw(wall[i].dw);
				wall[i].w = rand(cMinW,cMaxW);
				wall[i].h = rand(cMinH,cMaxH);
				wall[i].x = cResX + (wall[i].w>>1);
				wall[i].y = cResY - (wall[i].h>>1);
				wall[i].dw = draw_box(wall[i].x-(wall[i].w>>1),wall[i].y-(wall[i].h>>1),wall[i].x+(wall[i].w>>1),wall[i].y+(wall[i].h>>1));
				wall[i].memBox = false;			
			end;
		end;
		frameCount = 0;
	end;
	
	//cada cierto tiempo, lanza un laser
	if (rand(1,100) == 10 && !exists(TYPE missile2))
		missile2();
		play_wav(sndLaser,0,3);
	end;
	
	//incrementamos puntuacion
	score++;
	frameCount++;
	
	frame;
end;
end;

//proceso laser
process missile2()
begin
this.ancho = rand(cMinMissileW,cMaxMissileW);
this.alto = 2;
graph = new_map(this.ancho,this.alto,16);
map_clear(0,graph,MISSILE_COLOR);
x = cResX;
y = rand(cMinMissileY,cMaxMissileY);
this.fX = x;
this.fY = y;

loop
	//velociad segun dificultad
	this.vX = difficulty+1;
	
	//ajustamos velocidad/posicion
	this.fX-=this.vX;
	
	//si se sale de pantalla, muere
	if (x+(this.ancho>>1)<0)
		break;
	end;
	
	//actualizar posicion float-int
	positionToInt(id);
	
	frame;
end;
end;

//FUNCIONES
//===========================================

function int colCheckAABB(entity idEntity,int shapeBx,int shapeBy,int shapeBW,int shapeBH,int axis)
private
float vcX,vcY,hW,hH,oX,oY;
int ColDir;

begin
    //comprobamos los id de los procesos
	if (idEntity == 0) return 0; end;
	
		
	//Obtiene los vectores de los centros para comparar
	//teniendo en cuenta la velocidad del objeto principal
	//y el eje seleccionado en parametro axis
	if (axis==BOTHAXIS || axis==HORIZONTALAXIS || axis==INFOONLY )
		vcX = (idEntity.this.fX+idEntity.this.vX) - (shapeBx);
	else
		vcX = (idEntity.this.fX) - (shapeBx);
	end;
	if (axis==BOTHAXIS || axis==VERTICALAXIS || axis==INFOONLY )
		vcY = (idEntity.this.fY+idEntity.this.vY) - (shapeBy);
	else
		vcY = (idEntity.this.fY) - (shapeBy);
	end;
	
	// suma las mitades de los this.anchos y los this.altos
	hW =  (idEntity.this.ancho>>1) + (shapeBW>>1);
	hH = (idEntity.this.alto>>1) + (shapeBH>>1);
	
	colDir = 0;

    //si los vectores e x y son menores que las mitades de this.anchos y this.altos, ESTAN colisionando
	if (abs(vcX) < hW && abs(vcY) < hH) 
        
		//calculamos el sentido de la colision (top, bottom, left, or right)
        oX = hW - abs(vcX);
        oY = hH - abs(vcY);
        
		if (oX >= oY) 
            if (axis==BOTHAXIS || axis==VERTICALAXIS || axis==INFOONLY )
				if (vcY > 0) 			//Arriba
					colDir = COLUP;
					if (axis != INFOONLY)
						idEntity.this.fY += oY+idEntity.this.vY;
					end;
				else 
					colDir = COLDOWN;	//Abajo
					if (axis != INFOONLY)
					idEntity.this.fY -= oY-idEntity.this.vY;
					end;
				end;
			end;
        else
			if (axis==BOTHAXIS || axis==HORIZONTALAXIS || axis==INFOONLY)
				if (vcX > 0) 
					colDir = COLIZQ;	//Izquierda
					if (axis != INFOONLY)
					idEntity.this.fX += oX+idEntity.this.vX;
					end;
				else 
					colDir = COLDER;	//Derecha
					if (axis != INFOONLY)
						idEntity.this.fX -= oX-idEntity.this.vX;
					end;
				end;
			end;
	     end;
	end;
        
    //Devolvemos el sentido de la colision o 0 si no hay
    return colDir;

end;

//Escalamos la posicion de floats en enteros
//si la diferencia entre el float y el entero es una unidad
function positionToInt(entity idEntity)
begin
	//movemos si la posicion a cambiado partes enteras
	idEntity.x+= idEntity.this.fX - idEntity.x;
		
	//movemos si la posicion a cambiado partes enteras
	idEntity.y+= idEntity.this.fy - idEntity.y;
end;


//funcion que aplica la direccion de la colision en el objeto
function applyDirCollision(entity idEntity,int colDir,byte *objGrounded)
begin
	//acciones segun colision
	if (colDir == COLIZQ || colDir == COLDER) 
		idEntity.this.vX = 0;
	elseif (colDir == COLDOWN) 
		
			*objGrounded = true;
		
	elseif (colDir == COLUP) 
		idEntity.this.vY = 0;			//Flota por el techo	
		//idEntity.this.vY *= -1;		//Rebota hacia abajo con la velocida que subia
		//idEntity.this.vY = 2;		//Rebota hacia abajo con valor fijo
	end;
end;

//funcion que convierte un entero a string añadiendo ceros a la izquierda
function int2String(int entero,string *texto,int numDigitos)
begin
	//convertimos el entero a string
	*texto = itoa(entero);
	//añadimos 0 a la izquierda
	if (len(*texto) < numDigitos )
		repeat
			*texto = "0" + *texto;
		until(len(*texto)==numDigitos)
	end;
end;

//Funciona que anima el proceso que lo llama cambiando
//su grafico en cada llamada a la velocidad especificada
//Devuelve true cuando vuelve a empezar la animacion
function int wgeAnimate(int startFrame, int endFrame, int animationSpeed,int mode)
private
byte animFinished;	//flag de animacion terminada
entity idFather;	//entidad del proceso padre
begin
	animFinished = false;
	idFather = father.id;
	
	//no puede tener velocidad 0
	if (animationSpeed == 0) animationSpeed = 1; end;
	
	//si el proceso cambia de estado, se reseta cuenta
	if ( idFather.this.prevState <> idFather.this.state )
		idFather.this.frameCount = 0;
	end;
	
	//si el proceso no tiene grafico aun, se le asigna el startFrame
	if (idFather.graph == 0)
		idFather.graph = startFrame;
	end;
	
	//evitamos el primer frame
	if (idfather.this.frameCount <> 0)
	    //si toca animar en el frame correspondiente
		if ( (idfather.this.frameCount % animationSpeed ) == 0 )	
			//incrementamos frame si estamos en el rango
			if (idfather.graph < endFrame && idfather.graph >= startFrame)
				idfather.graph++;
			else 
				//si hemos llegado al final, pasamos al inicio
				if (mode == ANIM_LOOP)
					idfather.graph = startFrame; 
				end;
				animFinished =  true;
			end;
		else
		//si no nos toca animar, reseteamos a inicio en caso de que estemos fuera de rango
			if (idfather.graph > endFrame || idfather.graph < startFrame)
				idfather.graph = startFrame; 
			end;
		end;
	end;
	
	//incrementamos contador local 
	idfather.this.frameCount++;
	
	//devolvemos finalizado
	return animFinished;

end;

function int Wait(int t)
Begin
    t += timer[0];
    While(timer[0]<t) frame; End
    return t-timer[0];
End

//Funcion de chequeo de colision entre procesos elegiendo el eje
//Posiciona el objeto al borde del tile y devuelve un int con el sentido de la colision o 0 si no hay
function int colCheckProcess(entity idEntity,idEntityB, int axis)
private
float vcX,vcY,hW,hH,oX,oY;
int ColDir;

begin
    //comprobamos los id de los procesos
	if (idEntity == 0 || idEntityB == 0) return 0; end;
	
		
	//Obtiene los vectores de los centros para comparar
	//teniendo en cuenta la velocidad del objeto principal
	//y el eje seleccionado en parametro axis
	if (axis==BOTHAXIS || axis==HORIZONTALAXIS || axis==INFOONLY )
		vcX = (idEntity.this.fX+idEntity.this.vX) - (idEntityB.this.fX );
	else
		vcX = (idEntity.this.fX) - (idEntityB.this.fX );
	end;
	if (axis==BOTHAXIS || axis==VERTICALAXIS || axis==INFOONLY )
		vcY = (idEntity.this.fY+idEntity.this.vY) - (idEntityB.this.fY );
	else
		vcY = (idEntity.this.fY) - (idEntityB.this.fY );
	end;
	
	// suma las mitades de los this.anchos y los this.altos
	hW =  (idEntity.this.ancho>>1) + (idEntityB.this.ancho>>1);
	hH = (idEntity.this.alto>>1) + (idEntityB.this.alto>>1);
	
	colDir = 0;

    //si los vectores e x y son menores que las mitades de this.anchos y this.altos, ESTAN colisionando
	if (abs(vcX) < hW && abs(vcY) < hH) 
        
		//calculamos el sentido de la colision (top, bottom, left, or right)
        oX = hW - abs(vcX);
        oY = hH - abs(vcY);
        
		if (oX >= oY) 
            if (axis==BOTHAXIS || axis==VERTICALAXIS || axis==INFOONLY )
				if (vcY > 0) 			//Arriba
					colDir = COLUP;
					if (axis != INFOONLY)
						idEntity.this.fY += oY+idEntity.this.vY;
					end;
				else 
					colDir = COLDOWN;	//Abajo
					if (axis != INFOONLY)
					idEntity.this.fY -= oY-idEntity.this.vY;
					end;
				end;
			end;
        else
			if (axis==BOTHAXIS || axis==HORIZONTALAXIS || axis==INFOONLY)
				if (vcX > 0) 
					colDir = COLIZQ;	//Izquierda
					if (axis != INFOONLY)
					idEntity.this.fX += oX+idEntity.this.vX;
					end;
				else 
					colDir = COLDER;	//Derecha
					if (axis != INFOONLY)
						idEntity.this.fX -= oX-idEntity.this.vX;
					end;
				end;
			end;
	     end;
	end;
        
    //Devolvemos el sentido de la colision o 0 si no hay
    return colDir;

end;