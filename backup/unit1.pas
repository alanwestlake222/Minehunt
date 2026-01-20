unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, BCButton, BGRACustomDrawn, LCLType;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnEasy: TBCButton;
    btnMedium: TBCButton;
    btnHard: TBCButton;
    image1: TImage;
    imgBlank: TImage;
    imgMine: TImage;
    imgFlag: TImage;
    lblTimer: TLabel;
    lblMines: TLabel;
    lblCountMines: TLabel;
    Timer1: TTimer;
    procedure btnHardClick(Sender: TObject);
    procedure btnMediumClick(Sender: TObject);
    procedure btnEasyClick(Sender: TObject);
    procedure playAgain();
    procedure checkCell( row, col : integer);
    procedure CreateBoard();
    procedure RevealBoard();
    procedure clearOldBoard();
    procedure Timer1Timer(Sender: TObject);
    procedure aButtonMouseDown(Sender: TObject; Button: TMouseButton;
            Shift: TShiftState; X, Y: Integer);
  private
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

type
    TMineArray = array of array of TBCButton ;    //2d dynamic string array
    TImageArray = array of array of TImage ;      //2d dynamic image array

var
  MaxRows : integer;
  MaxCols :integer;
  numMines: integer;
  SquareSize : integer = 40;
  MineArray :  TMineArray;
  cellArray : TImageArray;
  NumFlags : Integer;
  NumFound : Integer;
  levelSelected : String;
  secs : integer;


function IsNumeric(s: String): boolean;
var
  i: integer;
begin
     Result := (length(s) > 0);
     for i := 1 TO length(s) do
         if not ((Char(s[i]) in ['1'..'9'])) then begin
           Result := False;
           exit;
         end;
end;


procedure TForm1.checkCell( row, col : integer);   //This recursive proc is the game logic
 begin
      //first check you didn't blow yourself up
      If MineArray[row, col].caption = 'Mine' Then begin
          Timer1.Enabled := False;
          RevealBoard();
          showmessage('!BANG! You Lost');
          playAgain();
          exit;
      end;

      //otherwise look through the board
      If MineArray[row, col].caption = 'Sea' Then begin     //ie sea

          MineArray[row, col].caption := 'checked';         //first mark it as checked so we don't do it again and end up looping
          cellArray[row, col].Picture := Nil;

          //look at the adjoining cells
          If (row > 0) And (col > 0) Then        //up left
              checkCell(row - 1, col - 1)
          Else
              exit;

          If row > 0 Then                        //up
              checkCell(row - 1, col)
          Else
              exit;

          If (row > 0) And (col < MaxCols) Then
              checkCell(row - 1, col + 1)         //up right
          Else
              exit;

          If col > 0 Then
              checkCell(row, col - 1)             //left
          Else
              exit;

          If col < MaxCols Then
              checkCell(row, col + 1)             //right
          Else
              exit;

          If (row < MaxRows) And (col > 0) Then
              checkCell(row + 1, col - 1)         //down left
          Else
              exit ;

          If (row < MaxRows) And (col < MaxCols) Then
              checkCell(row + 1, col + 1)         //down right
          Else
              exit ;

          If row < MaxRows - 1 Then
              checkCell(row + 1, col)             //down
          Else
              exit;
      end

      Else If IsNumeric(MineArray[row, col].caption) Then begin       //if it's not sea
          cellArray[row, col].visible :=false;
          MineArray[row, col].visible := True;    //show the number
          exit;
          end
      Else
          exit ;                                  //if an board edge just return
End ;


procedure TForm1.CreateBoard();
var
  i,c, row, col: integer;
  numLaid: integer;
  rdRow, rdCol, mineCounter: integer;
  MinesLaid: boolean;
  aButton: TImage;
  mineButton: TBCButton;

begin

  //set up the size of the 2 dynamic arrays
  setLength(MineArray,MaxRows,MaxCols);
  setLength(cellArray,MaxRows,MaxCols);

  //create cellarray images in rows and cols
  for i := 1 to MaxCols - 2 do
    for c := 1 to maxRows - 2 do begin
       aButton := TImage.Create(Form1);           // create image, Owner is Form1
       aButton.Name := 'row'+intToStr(i) + 'col' + IntToStr(c);  //name of cell is it's position
       aButton.Parent  := Form1;                  // determine where it is to be displayed
       aButton.Height  := SquareSize;
       aButton.Width   := aButton.Height;         // Width should correspond to the height of the buttons
       aButton.Left    := i * aButton.Width;      // Distance from left
       aButton.Top     := c * aButton.Height;     // distance from top
       aButton.Picture := Form1.imgBlank.picture;
       aButton.ShowHint:= false;
       aButton.OnMouseDown := @aButtonMouseDown;  //create mousedown event
       cellArray[i,c]:= aButton;                  // add it to the button array
    end;

  //create minearray buttons in rows and cols
  for i := 0 to MaxCols - 1 do
    for c := 0 to maxRows - 1 do begin
       mineButton := TBCButton.Create(Form1);         // create button, Owner is Form1
       mineButton.Parent  := Form1;                   // determine where it is to be displayed
       mineButton.Height  := SquareSize;
       mineButton.Width   := mineButton.Height;         // Width should correspond to the height of the buttons
       mineButton.Left    := i * mineButton.Width;      // Distance from left
       mineButton.Top     := c * mineButton.Height;     // distance from top
       mineButton.Font.Color := clRed;
       mineButton.Font.Size := 12;
       mineButton.GlobalOpacity :=50 ;
       mineButton.visible := false;
       MineArray[i,c]     := mineButton;             // add it to the button array
    end;

  //set up the board size and position components
  Form1.Height := MaxRows * aButton.Height + 10;   // Height of the form should correspond to the height of the buttons
  Form1.Width  := MaxCols * aButton.Width + 100 ;  // Width of the form to match the width of all buttons
  image1.Height := Form1.Height;
  image1.Width := Form1.width;
  lblCountMines.Top := 30;
  lblCountMines.Left := SquareSize * MaxRows + 10;
  lblMines.Top := 30;
  lblMines.Left := SquareSize * MaxRows + 40;
  BtnEasy.Top := 120;
  BtnEasy.Left := SquareSize * MaxRows + 20;
  btnMedium.Top := 180;
  btnMedium.Left := SquareSize * MaxRows + 20;
  btnHard.Top := 240;
  btnHard.Left := SquareSize * MaxRows + 20;

  //set the edges of the board
  For row := 0 To MaxRows-1 do begin
      MineArray[row, 0].caption := 'Edge' ;
      MineArray[row, MaxCols-1].caption := 'Edge';
  end;
  For col := 0 To MaxCols-1 do begin
      MineArray[0, col].caption := 'Edge' ;
      MineArray[MaxRows-1, col].caption := 'Edge';
  end;

  //initialise the rest of the Mineboard to Sea
  For row := 1 To MaxRows - 2 do
      For col := 1 To MaxCols - 2 do begin
           MineArray[row, col].caption := 'Sea' ;
      end;

  //now drop the mines around the Mineboard
  numLaid := 0 ;
  MinesLaid := False ;
  Randomize() ;
  While MinesLaid = False do begin
        rdRow := Random (MaxRows -1) ;
        rdCol := Random (MaxCols -1) ;
        If MineArray[rdRow, rdCol].caption = 'Sea' Then begin
           MineArray[rdRow, rdCol].caption := 'Mine';
           numLaid := numLaid + 1;
           If numLaid = numMines Then MinesLaid := true;
        end;
  end;

  //loop through mineboard and count the mines - store them in the grid array
  For row := 1 To MaxRows - 1 do
      For col := 1 To MaxCols - 1 do begin
          mineCounter := 0;
          If MineArray[row, col].caption = 'Sea' Then begin
              //found an empty space so see if there are any mines touching it
              If MineArray[row - 1, col - 1].caption = 'Mine' Then mineCounter := mineCounter + 1; //ul
              If MineArray[row - 1, col].caption = 'Mine' Then mineCounter := mineCounter + 1;     //up
              If MineArray[row - 1, col + 1].caption = 'Mine' Then mineCounter := mineCounter + 1; //ur
              If MineArray[row, col - 1].caption = 'Mine' Then mineCounter := mineCounter + 1;     //left
              If MineArray[row, col + 1].caption = 'Mine' Then mineCounter := mineCounter + 1;     //right
              If MineArray[row + 1, col - 1].caption = 'Mine' Then mineCounter := mineCounter + 1; //dl
              If MineArray[row + 1, col + 1].caption = 'Mine' Then mineCounter := mineCounter + 1; //dr
              If MineArray[row + 1, col].caption = 'Mine' Then mineCounter := mineCounter + 1;     //down
              If mineCounter > 0 Then MineArray[row, col].caption := IntToStr(mineCounter);
          end;
      end;
end;


procedure TForm1.btnEasyClick(Sender: TObject);
begin
     clearOldBoard();
     MaxRows := 8;
     MaxCols := 8;
     numMines := 3;
     levelSelected := 'Easy';
     secs :=0;
     lblTimer.caption := '0 Secs';
     NumFound := 0;
     NumFlags := 0;
     lblCountMines.caption := inttoStr(NumFlags) + '/' + inttoStr(numMines) ;
     CreateBoard();
end;


procedure TForm1.btnMediumClick(Sender: TObject);
begin
  clearOldBoard();
  MaxRows := 12;
  MaxCols := 12;
  numMines := 10;
  levelSelected := 'Medium';
  secs :=0;
  lblTimer.caption := '0 Secs';
  NumFound := 0;
  NumFlags := 0;
  lblCountMines.caption := inttoStr(NumFlags) + '/' + inttoStr(numMines) ;
  CreateBoard();
end;


procedure TForm1.btnHardClick(Sender: TObject);
begin
  clearOldBoard();
  MaxRows := 14;
  MaxCols := 14;
  numMines := 12;
  levelSelected := 'Hard';
  secs :=0;
  lblTimer.caption := '0 Secs';
  NumFound := 0;
  NumFlags := 0;
  lblCountMines.caption := inttoStr(NumFlags) + '/' + inttoStr(numMines) ;
  CreateBoard();
end;


procedure TForm1.aButtonMouseDown(Sender: TObject; Button: TMouseButton;
                                            Shift: TShiftState; X, Y: Integer);
var
  row,col,colrowPos,len: Integer;

begin
  if (Sender is Timage) then begin

    //if the game hasn't started yet ie this if first click then kick it off
    If Timer1.Enabled = False Then
       Timer1.Enabled := True;

    //now get the cell position from it's name
    len := Length(Timage(Sender).Name ) ;
    colrowPos := Pos('col',Timage(Sender).Name);     //eg name = row3col2 for row 11 col12
    row := strtoint(copy(Timage(Sender).Name, 4, colrowPos-4));
    col := strtoint(copy(Timage(Sender).Name, colrowpos+3, len-colrowPos));

    //then decide if we can flag - we use the hint component to store data
    If Button = mbRight Then begin

       If cellArray[row, col].hint = '.' Then begin  //if it's already a flag then unflag it(using a dot)

          cellArray[row, col].hint := '' ;
          cellArray[row, col].Picture := imgBlank.picture;
          NumFlags := NumFlags - 1;
          If MineArray[row, col].caption = 'Mine' Then NumFound := NumFound - 1;
          end

       else If (MineArray[row, col].caption <> 'checked') then begin  //flag it as a mine but not if it's already revealed

          cellArray[row, col].hint := '.';                                   //mark it with a dot (represents flag)
          cellArray[row, col].Picture := imgFlag.picture;
          NumFlags := NumFlags + 1;                                             //incr the flag count
          If MineArray[row, col].caption = 'Mine' Then NumFound := NumFound + 1        //if it's correct incr found count
          end;

    end;//If right mouse button

    //see if we've won
    lblCountMines.caption := inttoStr(NumFlags) + '/' + inttoStr(numMines) ;
    If (NumFound = numMines) And (NumFound = NumFlags) Then begin
       Timer1.Enabled := False ;
       RevealBoard() ;
       ShowMessage('You won!') ;
       playAgain();
    end ;

    //left click here
    If Button = mbLeft Then
       If cellArray[row, col].hint <> '.' Then      //if left click on an unflagged square
          checkCell(row, col)                       //check through the board

    end;
end;


procedure TForm1.clearOldBoard();                 //Erase the old controls if we're start a new game
var row,col : integer;
begin
     For row := 1 To high(cellarray) - 1 do
         For col := 1 To high(cellarray[0]) - 1 do
             If cellArray[row, col] <> Nil Then begin
                 cellArray[row, col].free;          //don't want memeory leaks
                 MineArray[row, col].free;
             End;
 End;


procedure TForm1.Timer1Timer(Sender: TObject);
begin
     secs:=secs+1;
     lblTimer.caption := intToStr(secs) + ' Secs';
end;


procedure TForm1.RevealBoard();                   //reveal the board when won or lost
var row,col : integer;
begin
      For row := 1 To MaxRows - 2  do
         For col := 1 To MaxCols - 2  do

             If (MineArray[row, col].caption = 'Sea') then  begin
               cellArray[row, col].picture := nil;
               MineArray[row, col].visible := false;
               end

             else if IsNumeric(MineArray[row, col].caption) then begin

                cellArray[row, col].visible :=false;       //take away pic and
                MineArray[row, col].visible := True;       //show the number
                end

             else If MineArray[row, col].caption = 'Mine' Then
                     If NumFound <> numMines Then begin       //if you lost
                         cellArray[row, col].visible :=true;
                         MineArray[row, col].visible := false;
                         cellArray[row, col].picture := imgMine.picture;
                     end;
end;


procedure TForm1.playAgain();                     //prompt for playing again or stopping
var again, BoxStyle : integer;
begin
  BoxStyle := MB_ICONQUESTION + MB_YESNO;
  again := Application.MessageBox('Play again?', 'Mines', BoxStyle);

    If again = IDYES Then begin
        clearOldBoard();
        secs:=0;
        lblTimer.caption := '0 Secs';
        NumFound := 0 ;
        NumFlags := 0 ;
        lblCountMines.caption := inttoStr(NumFlags) + '/' + inttoStr(numMines) ;
        CreateBoard();
    end
    Else
        Exit;
End;

end.

