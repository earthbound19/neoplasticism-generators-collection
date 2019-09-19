// source: https://www.openprocessing.org/sketch/381152/
// THIS IS A CODE SNAPSHOT. It apparently needs extensive work to run on Processing 3 local (if it even can at all), but it does work at openprocessing.org.

String rule="AABBCCDDDDDD";
String s =rule;
int blinkTime;
boolean blinkOn;
boolean slide;
float keep=0.5; 
float sl=(20+320)/2;

int [] A_gr;
int [] B_gr;

int [] A_add;
int [] B_add;

int [] C_add;
int [] C_st;
int [] C_ed;

int [] D_add;
int [] D_st;
int [] D_ed;

int [] x1;
int [] y1;
int [] x2;
int [] y2;

int [] xs1;
int [] ys1;
int [] xs2;
int [] ys2;

int [] rec_col;
int [] num,num2;

int n,m,k,u;

int rec_c;

void setup()
{
size(800,930);
background(251,252,244);
  
blinkTime = millis();
blinkOn = true;
slide = false;

crv();
patch();
colour();
}

void crv()
{
A_gr = new int[0];
B_gr = new int[0];

A_add = new int[0];
B_add = new int[0];

C_add = new int[0];
C_st = new int[0];
C_ed = new int[0];

D_add = new int[0];
D_st = new int[0];
D_ed = new int[0];

x1 = new int[0];
y1 = new int[0];
x2 = new int[0];
y2 = new int[0]; 

//first rectangle as canvas
append(x1,0);
append(y1,0);
append(x2,32);
append(y2,32);
  
for(n=0; n<31; n=n+1)
  {
    A_gr[n]=n+1;
    B_gr[n]=n+1;  
  }
 
for(n=0; n<rule.length(); n=n+1)
  {
    for(int f=0; f<x1.length; f++)
      {
        if(x1[f]>x2[f])
          {
            int dum = x2[f];
            x2[f]=x1[f];
            x1[f]=x1[f];
          }
        if(y1[f]>y2[f])
          {
            int dum = y2[f];
            y2[f]=y1[f];
            y1[f]=y1[f];
          }
      }
  
    
    
    
    
    String c = rule.charAt(n);
    if (c=="A")
      {
        int s_a = A_gr.length;
        int r_a = int(random(0,s_a-1));
        append(A_add,A_gr[r_a]);
        int r=x1.length;
        for (int j=0; j<r;j=j+1)
          {      
            if ((x1[j]<A_gr[r_a]) && (x2[j]>A_gr[r_a]))
              {
                append(x1,A_gr[r_a]);
                append(y1,y1[j]);
                append(x2,x2[j]);
                append(y2,y2[j]);
                x2[j]=A_gr[r_a];        
              }
          }
        A_gr=rmv(A_gr,r_a);
     }
  
  else if (c=="B")
    {
      int s_b = B_gr.length;
      int r_b = int(random(0,s_b-1));
      append(B_add,B_gr[r_b]);
      int s=y1.length;
      for (int w=0; w<s;w=w+1)
        {
          if ((y1[w]<B_gr[r_b]) && (y2[w]>B_gr[r_b]))
            {
              append(x1,x1[w]);
              append(y1,B_gr[r_b]);
              append(x2,x2[w]);
              append(y2,y2[w]);
              y2[w]=B_gr[r_b];        
            }
        }
     B_gr=rmv(B_gr,r_b);
   }
   
  else if (c=="C")
    {
      if (B_add.length + D_add.length == 0)
        {
          int s_c = A_gr.length;
          int r_c = int(random(0,s_c-1));
          append(A_add,A_gr[r_c]);
          int r=x1.length;
          for (int j=0; j<r;j=j+1)
            {      
              if ((x1[j]<A_gr[r_c]) && (x2[j]>A_gr[r_c]))
                {
                  append(x1,A_gr[r_c]);
                  append(y1,y1[j]);
                  append(x2,x2[j]);
                  append(y2,y2[j]);
                  x2[j]=A_gr[r_c];        
                }
            }
          A_gr=rmv(A_gr,r_c);
        }
      else
        {   
          int s_c = A_gr.length;
          int r_c = int(random(0,s_c-1));
          append(C_add,A_gr[r_c]);
          int [] C_cont = new int[0];
          append(C_cont,0);
          for (int q=0; q<B_add.length; q++)
            {append(C_cont,B_add[q]);}
          
          if (D_add.length>0)
            {
              int pos_c = D_add.length;
              for (k=0;k<pos_c;k=k+1)
                {
                  if((D_st[k]<(A_gr[r_c])) && (D_ed[k]>(A_gr[r_c]) ))
                    {append(C_cont,D_add[k]);}
                }
            }
          append(C_cont,32);
          C_cont=sort(C_cont);
          int C_pick = int(random(1,C_cont.length-1));
          append(C_st,C_cont[C_pick -1]);
          append(C_ed,C_cont[C_pick]);
          int r=x1.length;
          for (int j=0; j<r;j=j+1)
            {
              if ((x1[j]<=A_gr[r_c]) && (x2[j]>=A_gr[r_c]) && (y1[j]>=(C_cont[C_pick -1])) && ((y2[j]<=C_cont[C_pick])))
                {
                  append(x1,A_gr[r_c]);
                  append(y1,y1[j]);
                  append(x2,x2[j]);
                  append(y2,y2[j]);
                  x2[j]=A_gr[r_c];        
                }
            }
          A_gr=rmv(A_gr,r_c);
        }
    }
  
  else if (c=="D")
    {
      if (A_add.length +  C_add.length == 0)
        {
          int s_d = B_gr.length;
          int r_d = int(random(0,s_d-1));
          append(B_add,B_gr[r_d]);
          int s=y1.length;
          for (int w=0; w<s;w=w+1)
            {
              if ((y1[w]<B_gr[r_d]) && (y2[w]>B_gr[r_d]))
                {
                  append(x1,x1[w]);
                  append(y1,B_gr[r_d]);
                  append(x2,x2[w]);
                  append(y2,y2[w]);
                  y2[w]=B_gr[r_d];        
                }
            }
         B_gr=rmv(B_gr,r_d);
       }
      else
        {
          int s_d = B_gr.length;
          int r_d = int(random(0,s_d-1));
          append(D_add,B_gr[r_d]);
          int [] D_cont = new int[0];
          append(D_cont,0);
          for (int p=0; p<A_add.length; p++)
            {append(D_cont,A_add[p]);}
          if (C_add.length>0)
            {
              int pos_d = C_add.length;
              for (k=0;k<pos_d;k=k+1)
                {
                  if((C_st[k]<(B_gr[r_d])) && (C_ed[k]>((B_gr[r_d]))))
                    {append(D_cont,C_add[k]);}
                }
            }
          append(D_cont,32);
          D_cont=sort(D_cont);
       
          int D_pick = int(random(1,D_cont.length-1));
          append(D_st,D_cont[D_pick -1]);
          append(D_ed,D_cont[D_pick]);
          int s=y1.length;
          for (int w=0; w<s;w=w+1)
            {
              if ((y1[w]<=B_gr[r_d]) && (y2[w]>=B_gr[r_d]) && (x1[w]>=D_cont[D_pick -1]) && ((x2[w]<=D_cont[D_pick])))
                {
                  append(x1,x1[w]);
                  append(y1,B_gr[r_d]);
                  append(x2,x2[w]);
                  append(y2,y2[w]);
                  y2[w]=B_gr[r_d];        
                }
            }
         B_gr=rmv(B_gr,r_d);
       }
     
    }
  }
}


void patch()
{
num = new int[0];
rec_c=x1.length;

for(u =0; u<rec_c; u=u+1)
  {append(num,u);}
  
num = shf(num);
rec_c=x1.length;
int q=int(rec_c*keep);
  
xs1 = new int[0];
ys1 = new int[0];
xs2 = new int[0];
ys2 = new int[0]; 

for(int g=0; g<q; g=g+1)
  {
    append(xs1,x1[int(num[g])]);
    append(xs2,x2[int(num[g])]);
    append(ys1,y1[int(num[g])]);
    append(ys2,y2[int(num[g])]);
  }
}

void colour()
{
rec_col = new int[0];
int add_no=0;
int add;
for(u =0; u<x1.length; u=u+1)
  {
    add = int(random(0,12)); 
    if (add_no > (x1.length/6))
      {add = int(random(0,10));}
    append(rec_col,add);
    if (add>9)
      {add_no=add_no+1;}
  }
}

int[] rmv(int [] arr, int item)
{
  int [] outgoing = new int[0];
  for (int z=0; z<arr.length-1; z++)
    {
      if (z<item)  {append(outgoing,arr[z]);}
      else         {append(outgoing,arr[z+1]);}
    }
  return outgoing;
} 

int[] shf(int [] arr)
{
  int [] outgoing = new int[0];
  for (int z=arr.length-1; z>0; z=z-1)
    {
       int mv = int(random(0,z-1));
       int f = arr[z];
       int d = arr[mv];
       arr[mv]=f;
       arr[z]=d;
    }
  outgoing = arr;
  return outgoing;
} 
  

void draw(){
background(251,252,244);
for (int h=0; h<xs1.length;h=h+1)
  {
    rectMode(CORNERS);
    noStroke();
    int g = int(rec_col[h]);
    if       (g<4)  {fill(255,247,0);}
    else if  (g<7)  {fill(247,0,4);}
    else if  (g<10) {fill(4,4,160);}
    else            {fill(26,20,20);}
    
    rect((xs1[h])*25,(ys1[h])*25,(xs2[h])*25,(ys2[h])*25);
}

stroke(0);
strokeWeight(7);
strokeCap(SQUARE);

for (k=0;k<A_add.length; k=k+1)
  {line((A_add[k])*25,0,(A_add[k])*25,800);}
  
for (k=0;k<B_add.length; k=k+1)
  {line(0,(B_add[k])*25,800,(B_add[k])*25);}

for (k=0;k<C_add.length; k=k+1)
  {line((C_add[k])*25,((C_st[k])*25),(C_add[k])*25,(C_ed[k])*25);}

for (k=0;k<D_add.length; k=k+1)
  {line(((D_st[k])*25),(D_add[k])*25,(D_ed[k])*25,(D_add[k])*25);}
  
  rectMode(CORNERS);
  noStroke();
  fill(220);
  rect(0,800,width,900);
  
  noStroke();
  fill(190);
  rect(width-80,820,width-20,900-20);
  
  textSize(12);
  textAlign(CENTER,BOTTOM);
  fill(255);
  text("RESET", width-50, 850);
  textAlign(CENTER,TOP);
  text("ALL", width-50, 850);
  
  noStroke();
  fill(190);
  rect(width-160,820,width-100,900-20);
  
  textAlign(CENTER,BOTTOM);
  fill(255);
  text("SHUFFLE", width-130, 850);
  textAlign(CENTER,TOP);
  text("CURVE", width-130, 850);
  
  noStroke();
  fill(190);
  rect(width-240,820,width-180,900-20);
  
  textAlign(CENTER,BOTTOM);
  fill(255);
  text("SHUFFLE", width-210, 850);
  textAlign(CENTER,TOP);
  text("PATCH", width-210, 850);
  
  noStroke();
  fill(190);
  rect(width-320,820,width-260,900-20);
  
  textAlign(CENTER,BOTTOM);
  fill(255);
  text("SHUFFLE", width-290, 850);
  textAlign(CENTER,TOP);
  text("COLOUR", width-290, 850);
  
  float size=textWidth(s);
  
  noStroke();
  fill(255);
  rect(20,820,320,845);
  rect(20,855,320,880);
 
  noStroke();
  fill(0);
  textAlign(LEFT,CENTER);
  text(s,25,832);
  
  noStroke();
  fill(100);
  textAlign(LEFT,CENTER);
  text("RULESET (E TO ERASE",327,826);
  text("ENTER TO EXECUTE)",327,842);
  text("% COLOURED PATCH",327,867);
  
  text("0",25,867);
  text("100",294,867);
  
  fill(190);
  rectMode(CENTER);
  rect(sl,(855+880)/2,17,17);
  rectMode(CORNERS);
  
  stroke(0);
  strokeWeight(1);
  if (blinkOn)
    {line(25+1+size,830-7,25+1+size,830+10);}
  if (millis() - 500 > blinkTime)
    {
      blinkTime = millis();
      blinkOn = !blinkOn;
    }
    
  noStroke();
  fill(0);
  rect(0,900,width,height);
  
  smooth();
  noStroke();
  fill(200);
  textAlign(CENTER,CENTER);
  text("A - Vertical Line | B - Horizontal Line | C - Split Vertical Line | D - Split Horizontal Line",width/2,915);
}

void mouseDragged()
{
  if (mouseX < sl+12.5 && mouseX > sl-12.5 && mouseY < (855+880)/2 + 12.5 && mouseY > (855+880)/2 - 12.5)
  {
    sl= float(mouseX);
    if (sl<32.5)  {sl=32.5;}
    if (sl>307.5) {sl=307.5;}
    slide=true;
  }
}

void mouseReleased()
{
  keep = 1-(307.5-sl)/(307.5-32.5);
  if (slide==true)
  {
    patch();
    slide=false;
  }
}

void mouseClicked()
{
if  ((mouseX>width-80) && (mouseX<width-20) && (mouseY>820) && (mouseY<height-20))
    {
      rule="AABBCCDDDDDD";
      s =rule;
      keep=0.5; 
      setup();
      sl=(20+333)/2;
    }
    
if  ((mouseX>width-320) && (mouseX<width-260) && (mouseY>820) && (mouseY<height-20))
    {colour();}
    
if  ((mouseX>width-240) && (mouseX<width-180) && (mouseY>820) && (mouseY<height-20))
    {patch();}
    
if  ((mouseX>width-160) && (mouseX<width-100) && (mouseY>820) && (mouseY<height-20))
    {
      crv();
      patch();
    }
if  ((mouseX>32.5) && (mouseX<307.5) && (mouseY>855) && (mouseY<880))
    {
      sl=mouseX;
      slide=true;
      mouseReleased();
    }
}
 
void keyPressed()
{
int len = s.length;

if  (key=='e' || key=='E' && len>0)
    {s=s.substring(0,s.length-1);}
    
else if ((key=='A' || key=='B' || key=='C' || key=='D' || key=='a' || key=='b' || key=='c' || key=='d') && len<32)
   {
     if  (key=='A' || key=='a')  {s=s+"A";}
     if  (key=='B' || key=='b')  {s=s+"B";}
     if  (key=='C' || key=='c')  {s=s+"C";}
     if  (key=='D' || key=='d')  {s=s+"D";}
   }
   
else if (key==ENTER)
        {
          rule=s;
          setup();
        }
}