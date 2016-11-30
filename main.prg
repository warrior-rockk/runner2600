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

Const
	cResX = 160;
	cResY = 120;
	cVelX = 1;
	cScrollX = 3;
	cMinSpace = 20;
	cMaxSpace = 100;
	cMinH     = 10;
	cMaxH     = 50;
	cMinW     = 10;
	cMaxW     = 50;
	cMaxWalls = 10;
end;

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
	int wallColor[4] = (123,223,333,433);
end;

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

process main()


private
	int i;
	string strScore = 0;
	entity idActor;
	int gameState = SPLASH_ST;
	int idFont;
begin
	Scale_resolution = "0" + cResX*2 + "0" + CResY*2;
	set_mode(cResX,cResY,16);
	set_fps(60,0);
	map_clear(0,0,3050);
	idFont = load_fnt("fuente.fnt");
	misile1();
	loop
		switch (gameState)
			case SPLASH_ST:
				if (key(_enter))		
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
				gameState = PLAY_ST;
			end;
			case PLAY_ST:
			
				//Convertimos la puntuacion a string formato de 8 digitos
				int2String(score,&strScore,8);
				
				if (score % 100 == 0)
					gScrollX == 1 ? gVelX++ : gScrollX--;	
					difficulty++;
				end;
				
				if (idActor.this.state == DEAD_ST)
					gameState = GAMEOVER_ST;
				end;
				
				if (key(_r))
					gameState = RESET_ST;					
				end;				
				
			end;
			case GAMEOVER_ST:
				signal(all_process,s_freeze);
				map_clear(0,0,rgb(255,0,0));
				wait(10);
				map_clear(0,0,rgb(255,255,0));
				wait(10);
				map_clear(0,0,rgb(255,0,0));
				wait(10);
				map_clear(0,0,rgb(255,255,0));
				wait(10);
				map_clear(0,0,3050);
				wait(50);
				let_me_alone();
				delete_draw(0);
				delete_text(all_text);
				for (i=0;i<wallNum;i++)
					wall[i].memBox = false;
				end;
				write_var(idFont,10,10,0,strScore);
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

process player1()
private
	float grav = 0.4;
	byte grounded = false;
	int	  dir;					//Direccion de la colision
	int wallCheck = 0;
begin
this.ancho = 11;
this.alto = 14;
load_fpg("actor.fpg");
graph = 1;
x = 8;
y = 16;
this.fX = x;
this.fY = y;
this.state = IDLE_ST;
loop
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
	if (key(_up) && this.vY == 0)
		this.vY += -6;
	end;
	
	this.vY += grav;
	grounded = false;
	
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
			this.state = DEAD_ST;
		end;
	end;
	
	//actualizar posicion float-int
	positionToInt(id);
	
	if (this.vX > 0)
		flags = 0;
	elseif (this.vX < 0)
		flags = 1;
	end;
	
	//muerte
	if (y > cResY+20)
		this.state = DEAD_ST;
	end;
	
	this.prevState = this.state;
	
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


process misile1()
private
	int memBox;
	int i;
	int framecount=0;
begin
rand_seed(time());
drawing_color(wallColor[difficulty]);

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

loop
	drawing_color(wallColor[difficulty]);
	
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
	
	score++;
	frameCount++;
	
	frame;
end;
end;


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

//funcion que convierte un entero a string a�adiendo ceros a la izquierda
function int2String(int entero,string *texto,int numDigitos)
begin
	//convertimos el entero a string
	*texto = itoa(entero);
	//a�adimos 0 a la izquierda
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