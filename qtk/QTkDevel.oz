%
% Authors:
%   Donatien Grolaux (2000)
%
% Copyright:
%   (c) 2000 Universit� catholique de Louvain
%
% Last change:
%   $Date$ by $Author$
%   $Revision$
%
% This file is part of Mozart, an implementation
% of Oz 3:
%   http://www.mozart-oz.org
%
% See the file "LICENSE" or
%   http://www.mozart-oz.org/LICENSE.html
% for information on usage and redistribution
% of this file, and for a DISCLAIMER OF ALL
% WARRANTIES.
%
%  The development of QTk is supported by the PIRATES project at
%  the Universit� catholique de Louvain.


\define DEBUG

functor

import
%   System(show:Show)
   Tk
   Error
   QTk at 'QTkBare.ozf'
   Property(get)

export

   split:              Split
   splitGeometry:      SplitGeometry
   splitParams:        SplitParams
   condFeat:           CondFeat
   makeClass:          MakeClass
   execTk:             ExecTk
   lastInt:            LastInt
   returnTk:           ReturnTk
   tkInit:             TkInit
   checkType:          CheckType
   convertToType:      ConvertToType
   setAssertLevel:     SetAssertLevel
   assert:             Assert
   setGet:             SetGet
   qTkAction:          QTkAction
   qTkClass:           QTkClass
   subtracts:          Subtracts
   qTkTooltips:        TkToolTips
   setTooltips:        SetToolTips
   globalInitType:     GlobalInitType
   globalUnsetType:    GlobalUnsetType
   globalUngetType:    GlobalUngetType
   mapLabelToObject:   MapLabelToObject
   registerWidget:     RegisterWidget
   getWidget:          GetWidget
   qTk:                NQTk
   loadTk:             LoadTk
   loadTkPI:           LoadTkPI
   NewLook
   DefLook
   PropagateLook


require
   BootObject at 'x-oz://boot/Object'
   BootName   at 'x-oz://boot/Name'
prepare
   GetClass = BootObject.getClass
   OoFeat   = {BootName.newUnique 'ooFeat'}


%%% Functions and procedures that are heavily used when developping QTk widgets

   fun{Split Str}
      %
      % This function splits a string representing a tcl list into an Oz list
      %
      R
      fun{Loop L S A B}
         case L of X|Xs then
            case X
            of 32 then % space
               if S==0 andthen A==0 andthen B==0 then % no " { [ pending
                  R=Xs
                  nil
               else
                  X|{Loop Xs S A B}
               end
            [] 34 then % "
               if S==0 then
                  X|{Loop Xs 1 A B}
               else
                  X|{Loop Xs 0 A B}
               end
            [] 123 then % {
               X|{Loop Xs S A+1 B}
            [] 91 then % [
               X|{Loop Xs S A B+1}
            [] 93 then % ]
               X|{Loop Xs S A B-1}
            [] 125 then % }
               X|{Loop Xs S A-1 B}
            else
               X|{Loop Xs S A B}
            end
         else
            R=nil
            nil
         end
      end
      fun{Purge Str}
         case Str of X|Xs then
            if X==34 orelse X==123 orelse X==91 then
               {List.take Xs {Length Xs}-1}
            else
               Str
            end
         else
            Str
         end
      end
   in
      if Str==nil then nil else
         {Purge {Loop Str 0 0 0}}|{Split R}
      end
   end

   fun {SplitGeometry Str}
      %
      % This function splits a string of integers separated by control characters
      % into an Oz list of the integers. ( e.g "100x200+10+40" into [100 200 10 40])
      %
      R
      fun{Loop Str}
         case Str of X|Xs then
            if X>=48 andthen X=<57 then
               X|{Loop Xs}
            else
               R=Xs
               nil
            end
         else
            R=nil
            nil
         end
      end
   in
      if Str==nil then nil else
         {String.toInt {Loop Str}}|{SplitGeometry R}
      end
   end

   fun{CondFeat R F D}
      %
      % This function returns the specified feature of a record, or a default value
      % if the record doesn't have that feature
      %
      if {IsRecord R} andthen {HasFeature R F} then R.F else D end
   end


   fun{TkInit Var}
      %
      % This function returns a record that is Var minus several features that aren't
      % valid tk parameters.
      %
      {Record.adjoin
       {Record.filterInd Var
        fun{$ I R} {Int.is I}==false andthen
           {Member I [glue feature padx pady init return tooltips handle action look]}==false
        end}
       tkInit}
   end

   proc{SplitParams Rec L A B}
      %
      % This procedure splits Rec into two records where all features named in the
      % L list are placed into the B variable
      %
      {Record.partitionInd Rec
       fun{$ I _}
          {List.member I L}
       end
       B A}
   end

   fun{Subtracts Rec L}
      %
      % This function returns the record Rec minus all feature that are in the list L
      %
%      case L
%      of X|Xs then {Subtracts {Record.subtract Rec X} Xs}
%      else Rec
%      end
      {Record.filterInd Rec fun{$ I _} {Member I L}==false end}
   end

%   fun{RecordToTk R}
%      {List.toRecord
%       tk
%       {List.append
%       [1#{Label R}]
%       {List.map {Record.toListInd R}
%        fun{$ V}
%           case V of I#J then
%              if {IsInt I} then I+1#J else
%                 V
%              end
%           end
%        end}}}
%   end

   fun{LastInt R}
      fun{Max N L}
         case L of X|Xs then
            case X of I#_ then
               if {Int.is I} andthen I>N then
                  {Max I Xs}
               else
                  {Max N Xs}
               end
            end
         else
            N
         end
      end
   in
      {Max 0 {Record.toListInd R}}
   end

   %
   % These three variables are usual parameters to specify the type information of
   % widgets
   %

   GlobalInitType=r(glue:nswe
                    padx:natural
                    pady:natural
%                   return:free
                    feature:atom
                    parent:no
                    handle:free
                    tooltips:vs
                    look:no)

   GlobalUnsetType={Record.adjoinAt {Record.subtract GlobalInitType tooltips} return unit}

   GlobalUngetType={Record.adjoinAt {Record.subtract GlobalInitType tooltips} return unit}

   %% Taken from Tk.oz from Christian Schulte

%   Stok  = String.token
   Stoks = String.tokens
   S2F   = String.toFloat
   S2I   = String.toInt
   SIF   = String.isFloat
   SII   = String.isInt

%   V2S   = VirtualString.toString

   %%
   %% Some Character/String stuff
   %%
   local
      fun {TkNum Is BI ?BO}
         case Is of nil then BO=BI nil
         [] I|Ir then
            case I
            of &- then &~|{TkNum Ir BI BO}
            [] &. then &.|{TkNum Ir true BO}
            [] &e then &e|{TkNum Ir true BO}
            [] &E then &E|{TkNum Ir true BO}
            else I|{TkNum Ir BI BO}
            end
         end
      end
   in
%      fun {TkStringToString S}
%        S
%      end

      TkStringToAtom = StringToAtom

      fun {TkStringToInt S}
         %% Read a number and convert it to an integer
         OS IsAFloat in OS={TkNum S false ?IsAFloat}
         if IsAFloat andthen {SIF OS} then
            {FloatToInt {S2F OS}}
         elseif {Not IsAFloat} andthen {SII OS} then
            {S2I OS}
         else false
         end
      end

      fun {TkStringToFloat S}
         %% Read a number and convert it to a float
         OS IsAFloat in OS={TkNum S false ?IsAFloat}
         if IsAFloat andthen {SIF OS} then
            {S2F OS}
         elseif {Not IsAFloat} andthen {SII OS} then
            {IntToFloat {S2I OS}}
         else false
         end
      end

      fun {TkStringToListString S}
         {Stoks S & }
      end

      fun {TkStringToListAtom S}
         {Map {Stoks S & } TkStringToAtom}
      end

      fun {TkStringToListInt S}
         {Map {Stoks S & } TkStringToInt}
      end

      fun {TkStringToListFloat S}
         {Map {Stoks S & } TkStringToFloat}
      end
   end

   %% Back to my own code

   fun{ConvertToType Str Type}
      %
      % This function converts a string into the specified type
      %
      if {IsList Type} then
         R={List.dropWhile Type
            fun{$ E}
               {VirtualString.toString E}\=Str
            end}
      in
         if {Length R}==0 then
            {Exception.raiseError qtk(custom "Internal Error" "Can't convert "#Str#" to the correct type" "")}
            unit
         else
            {List.nth R 1}
         end
      else
         {Wait Str}
         case Type
         of no then Str
         [] nswe then {String.toAtom Str}
         [] pixel then try
                          {String.toInt Str}
                       catch _ then {String.toAtom Str} end
         [] vs then Str
         [] color then
            if {List.nth Str 1}==35 then %#RRGGBB
               BPV=({Length Str}-1) div 3
               RR GG BB T
               {List.takeDrop {List.drop Str 1} BPV RR T}
               {List.takeDrop T BPV GG BB}
               R G B
               [R G B]={List.map [RR GG BB] fun{$ C} {List.take {VirtualString.toString C#"0"} 2} end} % takes only the two most significant bytes
               fun{Convert V}
                  C={List.last V}



                  T=if C>=48 andthen C=<57 then C-48
                    elseif C>=97 andthen C=<102 then C-87
                    elseif C>=65 andthen C=<70 then C-55
                    else C end
               in
                  if {Length V}>1 then
                     T+16*{Convert {List.take V {Length V}-1}}
                  else
                     T
                  end
               end
            in
               c({Convert R} {Convert G} {Convert B})
            else
               {String.toAtom Str}
            end
         [] cursor then {String.toAtom Str}
         [] bitmap then {String.toAtom Str}
         [] atom then {String.toAtom Str}
         [] anchor then {String.toAtom Str}
         [] relief then {String.toAtom Str}
         [] boolean then Str=="1"
         [] natural then {TkStringToInt Str}
         [] int then {TkStringToInt Str}
         [] float then {TkStringToFloat Str}
         [] list then {TkStringToListString Str}
         [] listInt then {TkStringToListInt Str}
         [] listFloat then {TkStringToListFloat Str}
         [] listAtom then {TkStringToListAtom Str}
         [] scrollregion then
            fun{Split What}
               A B in
               {List.takeDropWhile What
                fun{$ C}
                   C\=32
                end
                A B}
               if B==nil then
                  A|nil
               else
                  A|{Split {List.drop B 1}}
               end
            end
            fun{ToNumber What}
               R
            in
               try
                  R={String.toFloat What}
               catch _ then skip end
               try
                  R={String.toInt What}
               catch _ then skip end
               if {IsFree R} then
                  {Exception.raiseError qtk(custom "Type Conversion Error" "Can't convert "#What#" to number")}
                  0
               else R end
            end
         in
            {List.toRecord q {List.mapInd
                              {List.map
                               {Split Str}
                               ToNumber}
                              fun{$ I S} I#S end}}
         else
            {Exception.raiseError qtk(custom "Type Error" "Target type "#Type#" is unkown")}
            unit
         end
      end
   end

   %%
   %% Functions required for the class definitions
   %%


   fun{Majus Str}
      {List.mapInd
       {VirtualString.toString Str}
       fun{$ I C}
          if I==1 then C-32 else C end
       end}
   end

define

   Lock={NewLock}
   NoArgs={NewName}
   NQTk={ByNeed fun{$} QTk end}
   QTkRegisterWidget={ByNeed fun{$} QTk.registerWidget end}

   fun{NewLook}
      L={NewDictionary}
   in
      look(set:proc{$ P}
                  {Dictionary.put L {Label P} P}
               end
           get:fun{$ P}
                  {Record.adjoin
                   {Dictionary.condGet L {Label P} P}
                   P}
               end)
   end

   DefLook=look(set:proc{$ P} skip end
                get:fun{$ P} P end)

   proc{ExecTk Obj Msg}
      if {Tk.returnInt 'catch'(v("{") b([Obj Msg]) v("}"))}==1 then
         {Exception.raiseError qtk(execFailed Obj Msg)}
      end
   end

   {Tk.send set(v 0)} % Initialize the v variable in Tcl/Tk

   proc{ReturnTk Obj M Type}
      N={LastInt M}
      if N==0 then {Exception.raiseError qtk(missingParameter 1 unknown M)} end
      Err={CheckType free M.N}
   in
      if Err==unit then skip else
         {Exception.raiseError qtk(typeError M.N Obj.widgetType Err M)}
      end
      case {Tk.return set(v("e [catch {set v [")
                          b([Obj {Record.subtract M N}])
                          v(']}];set e "$e $v"'))}
      of 49|32|_ then {Exception.raiseError qtk(execFailed Obj M)}
      [] 48|32|R then M.N={ConvertToType R Type}
      end
   end

   fun{CheckType Type V}
      %
      % This function checks the type of the variable V and returns
      % either unit if type is correct or a string that is a description of the
      % required type
      %
      if {IsList Type} then
         if {List.member V Type} then
            unit
         else
            {VirtualString.toAtom {List.foldL Type
                                   fun{$ I Z}
                                      if I==nil then Z else
                                         I#", "#Z
                                      end
                                   end
                                   nil}}
         end
      else
         case Type
         of no then
            unit
         [] auto(Cmd) then % the magical type : issue the command, catching the Tk error
            Ok
         in
            try
               if {Tk.returnInt 'catch'(v("{") Cmd v("}"))}==0
               then Ok=unit end
            catch _ then skip end
            if {IsFree Ok} then
               "A valid type for that parameter."
            else
               unit
            end
         [] relief then
            {CheckType [raised sunken flat ridge solid groove] V}
         [] anchor then
            {CheckType [n ne e se s sw w nw center] V}
         [] nswe then
            if {List.all {VirtualString.toString V}
                fun{$ C}
                   {List.member C "nswe"}
                end}
            then
               unit
            else
               "Any combination of n, s, w and e"
            end
         [] pixel then
            S={VirtualString.toString V}
            Conv
            E1 E2
         in
            if {List.member {List.last S} "cmip"} then
               Conv={List.take S {Length S}-1}
            else
               Conv=S
            end
            try
               _={String.toInt Conv}
            catch _ then E1=unit end
            try
               _={String.toFloat Conv}
            catch _ then E2=unit end
            if {IsFree E1} orelse {IsFree E2} then unit else
               "A screen distance (an integer or a pair int#c, int#m , int#i and int#p)"
            end
         [] free then
            if {IsFree V} then unit else
               "A free variable"
            end
         [] vs then
            if {VirtualString.is V} then unit else
               "A virtual string"
            end
         [] color then
            if ({Atom.is V} andthen {Tk.returnInt 'catch'(v("{ winfo rgb . ") V v("}"))}==0)
               orelse ({Record.is V}
                       andthen {Label V}==c
                       andthen {Record.arity V}==[1 2 3]
                       andthen {List.all [1 2 3]
                                fun{$ I}
                                   {HasFeature V I} andthen {Int.is V.I}
                                   andthen V.I>=0 andthen V.I=<255
                                end})
            then unit
            else "A color (either an atom that is a valid color or a record c(RR GG BB) where RR, GG and BB are integers between 0 and 255)"
            end
         [] cursor then
            Ok
         in
            lock Lock then
               try
                  if {Tk.returnInt 'catch'(v("{. configure -cursor") V
                                           v("}"))}==0
                  then Ok=unit end
               catch _ then skip end
            end
            if {IsFree Ok} then
               "An atom that represents a valid cursor."
            else
               unit
            end
         [] font then
            Ok
         in
            try
               if {Tk.returnInt 'catch'(v("{font metrics ") V v("-fixed }"))}==0
               then Ok=unit end
            catch _ then skip end
            if {IsFree Ok} then
               "A font (a virtualstring representing a valid font or a font object)"
            else
               unit
            end
         [] bitmap then
            Ok
         in
            lock Lock then
               try
                  if {Tk.returnInt 'catch'(v("{label .testlabel -bitmap ") V
                                           v(" ; destroy .testlabel }"))}==0
                  then Ok=unit end
               catch _ then skip end
            end
            if {IsFree Ok} then
               "A bitmap object or an atom that is a valid predefined bitmap"
            else
               unit
            end
         [] image then
            Ok
         in
            lock Lock then
               try
                  if {Tk.returnInt 'catch'(v("{label .testlabel -image ") V
                                           v(" ; destroy .testlabel }"))}==0
                  then Ok=unit end
               catch _ then skip end
            end
            if {IsFree Ok} then
               "An image object"
            else
               unit
            end
         [] atom then
            if {Atom.is V} then unit else
               "An atom"
            end
         [] boolean then
            if V==false orelse V==true then unit else
               "A boolean (true or false)"
            end
         [] float then
            if {Float.is V} orelse {Int.is V} then unit else
               "A float value"
            end
         [] natural then
            if {Int.is V} andthen V>=0 then unit else
               "An integer value >= 0"
            end
         [] integer then
            if {Int.is V} then unit else
               "An integer value"
            end
         [] action  then
            Ok
         in
            if {IsFree V} then skip % can't determine type for now
            elseif {Procedure.is V} then skip
            elsecase V
            of A#_ then
               if {IsFree A} then skip % in much cases this is determined later
               elseif A==toplevel then skip
               elseif A==widget then skip
               elseif {Port.is A} then skip
               elseif {Object.is A} then skip
               else
                  Ok=unit
               end
            else Ok=unit
            end
            if {IsFree Ok} then
               unit
            else
               "A command (a procedure or a pair object#method, port#message, toplevel#method, widget#method)"
            end
         [] scrollregion then
            if {Record.is V}
               andthen {Label V}==q
               andthen {Record.arity V}==[1 2 3 4]
               andthen {List.all [1 2 3 4]
                        fun{$ I}
                           {HasFeature V I} andthen ({Int.is V.I} orelse {Float.is V.I})
                        end}
            then
               unit
            else
               "A scrollregion (a record of the form q(X1 Y1 X2 Y2) where Xi and Yj are integers or floats)"
            end
         [] list then
            if {List.is V} then unit else
               "A list"
            end
         [] listVs then
            if {List.is V} andthen {List.all V VirtualString.is} then unit else
               "A list of virtual strings"
            end
         [] listBoolean then
            if {List.is V} andthen {List.all V fun{$ I} I==true orelse I==false end} then unit else
               "A list of booleans"
            end
         else
            {Exception.raiseError qtk(custom "Internal Error" "Requested type "#Type#" is unkown.")}
            unit
         end
      end
   end


   %%
   %% Error Formatter
   %%

   {Error.registerFormatter qtk
    fun {$ E}
       T = 'Error: QTk module'
    in
       case E
       of qtk(badParameter P O I) then
          error(kind:T
                msg:'Invalid parameter'
                items:[hint(l:'Parameter'
                            m:oz(P))
                       hint(l:'Widget type'
                            m:oz(O))
                       hint(l:'Operation'
                            m:oz(I))
                      ])
       [] qtk(missingParameter P O I) then
          error(kind:T
                msg:'Missing parameter'
                items:[hint(l:'Parameter'
                            m:oz(P))
                       hint(l:'Widget type'
                            m:oz(O))
                       hint(l:'Operation'
                            m:oz(I))
                      ])
       [] qtk(unsettableParameter P O I) then
          error(kind:T
                msg:'This parameter can only be set at creation time'
                items:[hint(l:'Parameter'
                            m:oz(P))
                       hint(l:'Widget type'
                            m:oz(O))
                       hint(l:'Operation'
                            m:oz(I))
                      ])
       [] qtk(ungettableParameter P O I) then
          error(kind:T
                msg:'This parameter can not be get its value'
                items:[hint(l:'Parameter'
                            m:oz(P))
                       hint(l:'Widget type'
                            m:oz(O))
                       hint(l:'Operation'
                            m:oz(I))
                      ])
       [] qtk(typeError P O Error I) then
          error(kind:T
                msg:"Incorrect Type"
                items:[hint(l:'Parameter'
                            m:oz(P))
                       hint(l:'Expected type'
                            m:Error)
                       hint(l:'Widget type'
                            m:oz(O))
                       hint(l:'Operation'
                            m:oz(I))
                      ])
       [] qtk(panelObject P M) then
          error(kind:T
                msg:"Object not in panel"
                items:[hint(l:'Object'
                            m:oz(P))
                       hint(l:'Widget type'
                            m:oz(panel))
                       hint(l:'Operation'
                            m:oz(M))
                      ])
       [] qtk(invalidAction P) then
          error(kind:T
                msg:"An action is defined with an invalid format"
                items:[hint(l:'Action'
                            m:oz(P))])
       [] qtk(custom M W I) then
          error(kind:T
                msg:M
                items:[hint(l:'Description'
                            m:W)
                       hint(l:'Operation'
                            m:oz(I))])
       [] qtk(custom M W) then
          error(kind:T
                msg:M
                items:[hint(l:'Description'
                            m:W)])
       [] qtk(badWidget W) then
          error(kind:T
                msg:"Invalid widget"
                items:if W==nil then
                         [hint(l:'Widget type'
                               m:oz({Label W}))]
                      else
                         [hint(l:'Widget type'
                               m:oz({Label W}))
                          hint(l:'Operation'
                               m:oz(W))
                         ]
                      end)
       [] qtk(execFailed O M) then
          error(kind:T
                msg:"Error while executing a command"
                items:[hint(l:'Object'
                            m:oz(O))
                       hint(l:'Operation'
                            m:oz(M))])
       [] qtk(other) then
          error(kind:T
                msg:"Unkown error")
       end
    end}

   %%
   %% Assertion stuff for checking parameter types
   %%

   AssertLevel={NewCell assert(init:full set:full get:full)}

   proc{SetAssertLevel What Level}
      if {List.member What [init set get]} andthen
         {List.member Level [full partial none]} then
         {Assign AssertLevel {Record.adjoinAt {Access AssertLevel}
                              What Level}}
      else
         {Exception.raiseError qtk(custom "Illegal AssertLevel" "Can only assert init, set and get to level full, partial or none" What#Level)}
      end
   end

   proc{Assert Widget TypeInfo Rec}
      if TypeInfo\=unit then % no type information => bypass test
         Op={Label Rec}
         Level={Access AssertLevel}.Op
      in
         if Level==full orelse Level==partial then % checks the type
            {Record.forAllInd Rec
             proc{$ I V}
                if {HasFeature TypeInfo.all I} then % the type is known
                   case Op
                   of init then
                      if {HasFeature TypeInfo.uninit I} then % the type can't be init
                         {Exception.raiseError qtk(badParameter I Widget Rec)}
                      end
                      if Level==full then % checks the type
                         Err={CheckType TypeInfo.all.I V}
                      in
                         if Err==unit then skip else
                            {Exception.raiseError qtk(typeError I Widget Err Rec)}
                         end
                      end
                   [] set then
                      if {HasFeature TypeInfo.unset I} then % the type can't be set
                         {Exception.raiseError qtk(unsettableParameter I Widget Rec)}
                      end
                      if Level==full then % checks the type
                         Err={CheckType TypeInfo.all.I V}
                      in
                         if Err==unit then skip else
                            {Exception.raiseError qtk(typeError I Widget Err Rec)}
                         end
                      end
                   [] get then
                      if {HasFeature TypeInfo.unget I} then % the type can't be get
                         {Exception.raiseError qtk(ungettableParameter I Widget Rec)}
                      end
                      if Level==full then % checks the type (always free here)
                         Err={CheckType free V}
                      in
                         if Err==unit then skip else
                            {Exception.raiseError qtk(typeError I Widget Err Rec)}
                         end
                      end
                   end
                else
                   {Exception.raiseError qtk(badParameter I Widget Rec)}
                end
             end}
         end
      end
   end

   %%
   %% Class definitions
   %%

   ToolTipsDelay=1000
   ToolTipsDisappearDelay=250
   TkToolTips
   ActiveTooltips={NewCell true}

   proc{SetToolTips B}
      if B==true orelse B==false then
         {Assign ActiveTooltips B}
      else
         {Exception.raiseError qtk(custom "Unable to enable/disable tooltips" "The parameter must be either true or false")}
      end
   end

   local
      Out
      ToolTipPort={NewPort Out}
      Last={NewCell nil}
      proc{Loop L}
         S={Access Last}\=nil
      in
         case L of Z|Zs then
            if {Access ActiveTooltips} then
               case Z
               of enter(Obj X Y) then
                  if S then
                     if {Access Last}==Obj then skip
                     else
                        {{Access Last} remove}
                        {Obj draw(X Y)}
                        {Assign Last Obj}
                     end
                  else
                     Chrono
                  in
                     thread
                        {Delay ToolTipsDelay}
                        Chrono=unit
                     end
                     {WaitOr Chrono Zs}
                     if {IsFree Chrono} then
                        skip
                     else
                        {Assign Last Obj}
                        {Obj draw(X Y)}
                     end
                  end
               [] leave(_) then
                  if S then
                     Chrono
                  in
                     {{Access Last} remove}
                     thread
                        {Delay ToolTipsDisappearDelay}
                        Chrono=unit
                     end
                     {WaitOr Chrono Zs}
                     if {IsFree Chrono} then
                        skip
                     else
                        {Assign Last nil}
                     end
                  end
               end
            else
               if {Access Last}\=nil then
                  {{Access Last} remove}
                  {Assign Last nil}
               else skip end
            end
            {Loop Zs}
         end
      end
      thread
         {Loop Out}
      end
   in
      class TkToolTips

         feat parent
            Toolwin:{NewCell nil}
            Message:{NewCell nil}
            Lock:{NewLock}

         attr text shown

         meth init(parent:P text:T)
            lock self.Lock then
               self.parent=P
               text<-T
               shown<-false
               thread
                  {P tkBind(event:"<Enter>" args:[int(x) int(y)]
                            action:ToolTipPort#enter(self))}
                  {P tkBind(event:"<Motion>" args:[int(x) int(y)]
                            action:ToolTipPort#enter(self))}
                  {P tkBind(event:"<Leave>" action:ToolTipPort#leave(self))}
               end
            end
         end

         meth unBindedInit(parent:P text:T)
            lock self.Lock then
               self.parent=P
               text<-T
               shown<-false
            end
         end

         meth enter(X Y)
            {Send ToolTipPort enter(self X Y)}
         end

         meth leave
            {Send ToolTipPort leave(self)}
         end

         meth set(T)
            lock self.Lock then
               text<-T
               if @shown then
                  try
                     {{Access self.Message} tk(configure text:@text)}
                  catch _ then skip end
               else skip end
            end
         end

         meth get(T)
            lock self.Lock then
               T=@text
            end
         end

         meth draw(MX MY)
            lock self.Lock then
               try
                  WX={Tk.returnInt winfo(rootx self.parent)} % +{Tk.returnInt winfo(width self.parent)}
                  WY={Tk.returnInt winfo(rooty self.parent)}
                  H={Tk.returnInt winfo(height self.parent)}
                  X Y
                  M
                  T
               in
                  if {Access self.Toolwin}==nil then
                     T={New Tk.toplevel tkInit(withdraw:true bg:black width:1 height:1
                                               visual:{Tk.return winfo(visual self.parent)}
                                               colormap:self.parent)}
                     M={New Tk.message tkInit(parent:T text:@text
                                              bg:'#e4e2bc' aspect:800
                                              font:'helvetica 8')}
                     {Tk.send pack(M padx:1 pady:1)}
                     {Assign self.Toolwin T}
                     {Assign self.Message M}
                  else
                     T={Access self.Toolwin}
                     M={Access self.Message}
                     {M tk(configure text:@text)}
                  end
                  if MX>64 then X=WX+MX else X=WX end
                  if {Abs H-MY}>64 then Y=WY+MY+16 else Y=WY+H end
                  {Tk.batch [wm(overrideredirect T true)
                             wm(geometry T '+'#{IntToString (X+4)}#'+'#{IntToString (Y+2)})
                             wm(deiconify T)
                             wm(geometry T '+'#{IntToString (X+4)}#'+'#{IntToString (Y+2)})]}
               catch _ then skip end
               shown<-true
            end
         end

         meth remove
            lock self.Lock then
               try
                  {Tk.send wm(withdraw {Access self.Toolwin})}
               catch _ then skip end
               shown<-false
            end
         end

         meth hide
            lock self.Lock then
               try
                  {{Access self.Toolwin} tkClose}
               catch _ then skip end
               {Assign self.Toolwin nil}
               shown<-false
            end
         end

      end
   end

   class SetGet % bare set and get functionalitites

      prop locking

      meth set(...)=M
         lock
            {ExecTk self {Record.adjoin M configure}}
         end
      end

      meth get(...)=M
         lock
            L={Record.toListInd M}
            Type
         in
            {ForAll L
             proc{$ R}
                case R
                of type#X then Type=X
                else skip end
             end}
            if {IsFree Type} then Type=no else skip end
            {ForAll L
             proc{$ R}
                case R
                of type#_ then skip
                [] X#Y then
                   {ReturnTk self cget("-"#X Y) Type}
                end
             end}
         end
      end

      meth return(...)=M
         lock
            L
            Type
            Ret
            Return
            InLabel
            InList
            ReturnNu
         in
            L={List.filter
               {Record.toListInd M}
               fun{$ R}
                  case R
                  of type#X then
                     Type=X
                     false
                  else true end
               end}
            if {IsFree Type} then Type=no else skip end
            ReturnNu={List.foldL L
                      fun{$ Z R}
                         case R of Nu#F then
                            if {Int.is Nu} andthen Nu>Z andthen {IsFree F} then Nu else Z end
                         else Z end
                      end
                      0}
            if ReturnNu<2 then raise error(incorrectReturnVariable) end else skip end
            InList={List.filterInd L
                    fun{$ I R}
                       case R
                       of 1#X then
                          InLabel=X
                          false
                       [] !ReturnNu#V then
                          Return=V
                          false
                       else true
                       end
                    end}
            {self tkReturn({List.toRecord InLabel InList} Ret)}
            Return={ConvertToType Ret Type}
            {Wait Return}
         end
      end

      meth exec(...)=M
         lock
            {self {Record.adjoin M tk}}
         end
      end

   end

   class QTkAction % QTk action class

      prop locking

      attr Action

      feat Toplevel Parent

      meth init(parent:P action:A<=proc{$} skip end)
         lock
            self.Parent=P
            self.Toplevel=P.toplevel
            QTkAction,set(A)
         end
      end

      meth action(A)
         A=self.Toplevel.port#r(self execute)
      end

      meth set(A)
         lock
            Action<-A
         end
      end

      meth get(A)
         lock
            A=@Action
         end
      end

      meth execute(...)=M
         lock
            Err
            fun{Adjoin Xs}
               if M==execute then Xs else
                  Max={List.foldR
                       {Arity Xs} fun{$ Old N}
                                     if {IsInt N} andthen N>Old then N else Old end
                                  end 0}
               in
                  {Record.adjoin
                   {List.toRecord r
                    {List.mapInd
                     {Record.toList M}
                     fun{$ I E} I+Max#E end}}
                   Xs}
               end
            end
         in
            if {Procedure.is @Action} then
               {Procedure.apply @Action {Record.toList M}}
            else
               case @Action
               of widget#Xs then {self.Parent {Adjoin Xs}}
               [] toplevel#Xs then {self.Toplevel {Adjoin Xs}}
               [] X#Xs then
                  if {Object.is X} then {X {Adjoin Xs}}
                  elseif {Port.is X} then
                     {Send X {Adjoin Xs}}
                  else
                     Err=unit
                  end
               else
                  Err=unit
               end
            end
            if {IsDet Err} then
               {Exception.raiseError qtk(invalidAction @Action)}
            end
         end
      end

   end

   class QTkClass % QTk mixin class

      prop locking

      from SetGet

      feat
         ToolTip
         widgetType:unknown
         tooltipsAvailable:true
         toplevel
         parent
         typeInfo:unit % different from unit means type checking is on : r(init:r unset:r unget:r)

      meth init(...)=M
         lock
            self.parent=M.parent
            self.toplevel=M.parent.toplevel
            {Assert self.widgetType self.typeInfo M}
            if {HasFeature self action} then % action widget
               self.action={New QTkAction init(parent:self action:{CondFeat M action proc{$} skip end})}
            end
            if self.tooltipsAvailable==true then % this widget has got a tooltips
               {self SetToolTip(M)}
            end
         end
      end

      meth set(...)=M
         lock
            {Assert self.widgetType self.typeInfo M}
            if {HasFeature self action} andthen {HasFeature M action} then
               {self.action set(M.action)}
            end
            if self.tooltipsAvailable andthen {HasFeature M tooltips} then
               {self SetToolTip(M)}
            end
            SetGet,{Subtracts M [action tooltips]}
         end
      end

      meth get(...)=M
         lock
            {Assert self.widgetType self.typeInfo M}
            if {HasFeature self action} andthen {HasFeature M action} then
               {self.action get(M.action)}
            end
            if self.tooltipsAvailable andthen {HasFeature M tooltips} then
               M.tooltips=if {IsFree self.ToolTip} then
                             ""
                          else
                             {self.ToolTip get($)}
                          end
            end
            if self.typeInfo==unit then
               SetGet,{Subtracts M [action tooltips]}
            else
               {Record.forAllInd {Subtracts M [action tooltips]}
                proc{$ I R}
                   SetGet,get(I:R type:self.typeInfo.all.I)
                end}
            end
         end
      end

      meth SetToolTip(M)
         lock
            if {HasFeature M tooltips} then
               if {IsFree self.ToolTip} then
                  self.ToolTip={New TkToolTips init(parent:self text:M.tooltips)}
               else
                  {self.ToolTip set(M.tooltips)}
               end
            else skip end
         end
      end

      meth bind(action:A<=proc{$} skip end event:E args:G<=nil)
         lock
            {self tkBind(event:E
                         action:{{New QTkAction init(parent:self action:A)} action($)}
                         args:G)}
         end
      end

      meth getFocus(force:F<=false)
         lock
            {ExecTk focus if F then o("-force" self) else o(self) end}
         end
      end

      meth setGrab(global:G<=false)
         lock
            {ExecTk grab if G then o("-global" self) else o(self) end}
         end
      end

      meth releaseGrab
         lock
            {ExecTk grab o(release self)}
         end
      end

      meth getGrabStatus(G)
         lock
            {ReturnTk grab o(status self G) atom}
         end
      end

      meth 'raise'(1:W<=NoArgs)
         lock
            if W==NoArgs then
               {ExecTk 'raise' o(self)}
            else
               {ExecTk 'raise' o(self W)}
            end
         end
      end

      meth lower(1:W<=NoArgs)
         lock
            if W==NoArgs then
               {ExecTk lower o(self)}
            else
               {ExecTk lower o(self W)}
            end
         end
      end

      meth winfo(...)=M
         lock
            R=r(cells:natural
                colormapfull:boolean
                depth:natural
                fpixels:exception %%%%%%%%%
                geometry:exception %%%%%%%%%%%
                height:natural
                id:no
                ismapped:boolean
                name:no
                parent:no
                pixels:exception %%%%%%%%%
                pointerx:natural
                pointery:natural
                pointerxy:exception %%%%%%
                reqheight:natural
                reqwidth:natural
                rgb:exception %%%%%
                rootx:natural
                rooty:natural
                screen:no
                screencells:natural
                screendepth:natural
                screenheight:natural
                screenmmheight:natural
                screenmmwidth:natural
                screenvisual:atom
                screenwidth:natural
                server:no
                toplevel:exception %%%%%%%
                viewable:boolean
                visual:atom
                visualid:no
                visualsavailable:exception %%%%%%%
                vrootheight:natural
                vrootwidth:natural
                vrootx:natural
                vrooty:natural
                width:natural
                x:natural
                y:natural)

         in
            {Record.forAllInd M
             proc{$ I V}
                if {HasFeature R I} then % parameter is correct
                   Err={CheckType free V}
                in
                   if Err==unit then skip
                   else
                      {Exception.raiseError qtk(typeError I self.widgetType Err M)}
                   end
                   V=if R.I==exception then % special parameters
                        case I
                        of fpixels then % function as still one parameter is missing
                           fun{$ P}
                              Err={CheckType pixel P}
                           in
                              if Err==unit then skip
                              else
                                 {Exception.raiseError qtk(typeError I self.widgetType Err M)}
                              end
                              {ConvertToType {Tk.return winfo(I self P)} float}
                           end
                        [] geometry then
                           {List.toRecord geometry
                            {List.mapInd
                             {SplitGeometry {Tk.return winfo(I self)}}
                             fun{$ I V}
                                case I
                                of 1 then width
                                [] 2 then height
                                [] 3 then x
                                [] 4 then y
                                end#V
                             end}}
                        [] pixels then
                           fun{$ P}
                              Err={CheckType pixel P}
                           in
                              if Err==unit then skip
                              else
                                 {Exception.raiseError qtk(typeError I self.widgetType Err M)}
                              end
                              {ConvertToType {Tk.return winfo(I self P)} natural}
                           end
                        [] pointerxy then
                           {List.toRecord pointerxy
                            {List.mapInd
                             {Split {Tk.return winfo(I self)}}
                             fun{$ I V}
                                case I
                                of 1 then x
                                [] 2 then y
                                end#{String.toInt V}
                             end}}
                        [] rgb then
                           fun{$ P}
                              Err={CheckType color P}
                           in
                              if Err==unit then skip
                              else
                                 {Exception.raiseError qtk(typeError I self.widgetType Err M)}
                              end
                              {List.toRecord rgb
                               {List.mapInd
                                {Split {Tk.return winfo(I self P)}}
                                fun{$ I V}
                                   case I
                                   of 1 then red
                                   [] 2 then green
                                   [] 3 then blue
                                   end#({String.toInt V} div 256)
                                end}}
                           end
                        [] toplevel then self.toplevel
                        [] visualsavailable then
                           {List.map
                            {Split {Tk.return winfo(I self includeids)}}
                            fun{$ Visual}
                               {List.toRecord visual
                                {List.mapInd
                                 {Split Visual}
                                 fun{$ I V}
                                    case I
                                    of 1 then visual#{ConvertToType V atom}
                                    [] 2 then depth#{ConvertToType V natural}
                                    [] 3 then id#V
                                    end
                                 end}}
                            end}
                        end
                     else
                        {ConvertToType {Tk.return winfo(I self)} R.I}
                     end
                else
                   {Exception.raiseError qtk(badParameter I self.widgetType M)}
                end
             end}
         end
      end


      meth close
         lock
            try
               {self destroy}
            catch _ then skip end
            {Tk.send destroy(self)}
         end
      end

      meth destroy
         lock
            skip
         end
      end
   end

   Widgets={NewDictionary}

   proc{RegisterWidget M}
      try
         {Dictionary.put Widgets M.widgetType
          r(feature:{CondFeat M feature false}
            object:M.{VirtualString.toAtom qTk#{Majus M.widgetType}})}
      catch _ then
         {Exception.raiseError qtk(custom "Unable to register a widget" "The specified module is not a correct QTk widget module" M)}
      end
   end

   fun{GetWidget M}
      P={Dictionary.condGet Widgets M r(object:nil)}.object
   in
      if P==nil then
         E
      in
         try
            E={QTkRegisterWidget M $}.{VirtualString.toAtom qTk#{Majus M}}
         catch _ then
            {Exception.raiseError qtk(custom "Unable to register a widget" "Missing or incorrect widget name" M)}
            E=nil
         end
         E
      else
         P
      end
   end

%   fun{MakeClass ClassName Description}
%      {Class.new [ClassName] q
%       {Record.map
%       {Record.filter Description
%        fun{$ V}
%           {IsDet V} andthen {IsRecord V} andthen {HasFeature V feature}
%        end}
%       fun{$ V}
%          V.feature
%       end}
%       [locking]}
%   end

%   fun{NewFeat Class Desc}
%      {New {MakeClass Class Desc} Desc}
%   end

   fun{MakeClass ClassName Description}
      {Class.new [ClassName] q
       {Record.map
        {Record.filter Description
         fun{$ V}
            {IsDet V} andthen {IsRecord V} andthen {HasFeature V feature}
         end}
        fun{$ V}
           V.feature
        end}
       [locking]}
   end

   fun{GetLook Rec}
      {{CondFeat Rec look DefLook}.get Rec}
   end

   fun{PropagateLook Rec}
      Look={CondFeat Rec look DefLook}
   in
      {GetLook
       {Record.mapInd Rec
        fun{$ I V}
           if {IsInt I} andthen {IsDet V} andthen {IsRecord V} then
              L=if {HasFeature V look}==false then
                   {Record.adjoinAt V look Look}
                else
                   V
                end
           in
              {GetLook L}
           else
              V
           end
        end}}
   end

   fun{NewFeat Class Desc}
      {New {MakeClass Class Desc} {PropagateLook Desc}}
   end

   fun{MapLabelToObject R}
      Name={Label R}
      A={Dictionary.condGet Widgets Name nil}
      D=if A\=nil then A else
\ifndef DEBUG
         {fun{$}
             E
          in

             %%
             %% A flaw in the system prevents the following lines from working :-(
             %%

%            try
%               %%
%               %% unknown widget : first tries to load it on the fly
%               %%
%               M
%            in
%               [M]={Module.link [{VirtualString.toString "QTk"#{Majus Name}#".ozf"}]}
%               {Wait M}
%               {RegisterWidget M}
%            catch _ then E=unit end

             try
                %%
                %% unknown widget : first tries to load it on the fly
                %%
                if {IsFree {QTkRegisterWidget Name $}} then E=unit end
             catch _ then E=unit end
             if {IsDet E} then
                %%
                %% secondly tries to build one on the fly !
                %%
                WidgetClass
             in
                try
                   UnknownWidget
                in
                   if {HasFeature R action} then
                      class UnknownWidget
                         feat
                            widgetType:Name
                            action
                         from QTkClass
                         meth unknownWidget(...)=M
                            QTkClass,{Record.adjoin M init}
                            Tk.Name,{Record.adjoin {TkInit M}
                                     tkInit(action:{self.action action($)})}
                         end
                         meth otherwise(M)
                            {Tk.send M}
                         end
                      end
                   else
                      class UnknownWidget
                         feat widgetType:Name
                         from QTkClass
                         meth unknownWidget(...)=M
                            QTkClass,{Record.adjoin M init}
                            Tk.Name,{TkInit M}
                         end
                         meth otherwise(M)
                            {Tk.send M}
                         end
                      end
                   end
                   WidgetClass={Class.new [Tk.{Label R} UnknownWidget] nil nil [locking]}
                catch _ then skip end
                if {IsFree WidgetClass} then
                   {Exception.raiseError qtk(badWidget R)}
                end
             end
             local
                X={Dictionary.condGet Widgets Name nil}
             in
                if X==nil then
                   {Exception.raiseError qtk(badWidget R)}
                   nil
                else
                   X
                end
             end
          end}
\else
           {fun{$}
               {Exception.raiseError qtk(badWidget R)}
               nil
            end}
\endif
        end
      Object
      proc{SetHandle}
         if {HasFeature R handle} then
            R.handle=Object
         end
         if {HasFeature R feature} then
            (R.parent).(R.feature)=Object
         end
      end
      case D.feature
      of true then
         Object={NewFeat D.object R}
         {SetHandle}
      [] menu then
         Object={NewFeat D.object R}
         if {HasFeature R handle} then
            R.handle=Object
         end
      [] false then
         Object={New D.object R}
         {SetHandle}
      [] unknown then
         Object={New D.object {Record.adjoin R unknownWidget}}
         {SetHandle}
      [] S then %% special support for scrollable widgets !
         if S==scroll orelse S==scrollfeat then
            if {CondFeat R tdscrollbar false} orelse {CondFeat R lrscrollbar false} then
               Type={Label R}
               B
               {SplitParams R [tdscrollbar lrscrollbar scrollwidth] _ B}
               class ScrollWidget
                  from Tk.frame QTkClass
                  meth init
                     lock
                        QTkClass,init(parent:R.parent)
                        Tk.frame,tkInit(parent:R.parent)
                        if S==scroll then
                           self.Type={New D.object {Record.adjoinAt R parent self}}
                        else
                           self.Type={NewFeat D.object {Record.adjoinAt R parent self}}
                        end
                        {Tk.batch [grid(self.Type row:0 column:0 sticky:nswe)
                                   grid(rowconfigure self 0 weight:1)
                                   grid(columnconfigure self 0 weight:1)]}
                        if {CondFeat B tdscrollbar false} then
                           self.tdscrollbar={New {Dictionary.get Widgets tdscrollbar}.object
                                             tdscrollbar(parent:self width:{CondFeat B scrollwidth 10})}
                           {Tk.send grid(self.tdscrollbar row:0 column:1 sticky:ns)}
                           {Tk.addYScrollbar self.Type self.tdscrollbar}
                        end
                        if {CondFeat B lrscrollbar false} then
                           self.lrscrollbar={New {Dictionary.get Widgets lrscrollbar}.object
                                             lrscrollbar(parent:self width:{CondFeat B scrollwidth 10})}
                           {Tk.send grid(self.lrscrollbar row:1 column:0 sticky:we)}
                           {Tk.addXScrollbar self.Type self.lrscrollbar}
                        end
                        if {HasFeature R handle} then
                           R.handle=self.Type
                        end
                        if {HasFeature R feature} then
                           (R.parent).(R.feature)=self.Type
                        end
                     end
                  end
                  meth set(...)=M
                     {self.Type M}
                  end
                  meth get(...)=M
                     {self.Type M}
                  end
                  meth destroy
                     lock
                        {self.Type destroy}
                        if {CondFeat B tdscrollbar false} then
                           {self.tdscrollbar destroy}
                        end
                        if {CondFeat B lrscrollbar false} then
                           {self.lrscrollbar destroy}
                        end
                     end
                  end
                  meth otherwise(M)
                     {self.Type M} %% passes the messages to the main object automatically
                  end
               end
               ScrollObj={Class.new [ScrollWidget] q
                          if {CondFeat B tdscrollbar false} then
                             if {CondFeat B lrscrollbar false} then
                                q(Type tdscrollbar lrscrollbar)
                             else
                                q(Type tdscrollbar)
                             end
                          else
                             q(Type lrscrollbar)
                          end
                          [locking]}
            in
               Object={New ScrollObj init}
            else
               %% no scrollbars, use the normal widget
               Object=if S==scrollfeat then
                         {NewFeat D.object R}
                      else
                         {New D.object R}
                      end
               {SetHandle}
            end
         else
            {Exception.raiseError qtk(custom "Internal Error" "Invalid feature code" S)}
            Object=nil
         end
      end
   in
      Object
   end

   TkClass =
   {List.last
    {Arity
     {GetClass
      {New class $ from Tk.frame meth init skip end end init}}
     . OoFeat}}

   fun{TkLoad FileName TkName}
      {ExecTk load FileName}
      class $
         from Tk.frame
         feat !TkClass:TkName
      end
   end

   fun{TkLoadPI FileName TkName}
      P={Property.get 'platform'}.os
   in
      {TkLoad
       FileName#"-"#P#if P==win32 then ".dll" else ".so" end
       TkName}
   end

   fun{RegisterLoadTkWidget TkClass TkName}
      QTkName={VirtualString.toAtom qTk#{Majus TkName}}
      class Temp
         feat widgetType:TkName
         from QTkClass TkClass
         meth !TkName(...)=M
            QTkClass,{Record.adjoin M init}
            TkClass,{TkInit M}
         end
         meth otherwise(M)
%           {ExecTk self M}
            {self tk(M)}
         end
      end
   in
      {RegisterWidget r(widgetType:TkName
                        feature:false
                        QTkName:Temp)}
      true
   end

   fun{LoadTk FileName TkName}
      try
         {RegisterLoadTkWidget {TkLoad FileName TkName} TkName}
      catch _ then false end
   end

   fun{LoadTkPI FileName TkName}
      try
         {RegisterLoadTkWidget {TkLoadPI FileName TkName} TkName}
      catch _ then false end
   end

end
