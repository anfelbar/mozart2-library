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

functor

import
   Tk
   QTkDevel(tkInit:             TkInit
            mapLabelToObject:   MapLabelToObject
            subtracts:          Subtracts
            qTkClass:           QTkClass
            returnTk:           ReturnTk
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget
            splitParams:        SplitParams
            propagateLook:      PropagateLook)

export
   WidgetType
   Feature
   QTkScrollframe

define

   WidgetType=scrollframe
   Feature=scrollfeat

   class QTkScrollframe

      from Tk.canvas QTkClass %% from a canvas bcz a canvas is scrollable

      prop locking

      feat
         widgetType:WidgetType
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:no
                           borderwidth:pixel
                           cursor:cursor
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           relief:relief
                           takefocus:boolean
                           background:color bg:color
                           colormap:no
                           height:pixel
                           width:pixel
                           visual:no
                           lrscrollbar:boolean
                           tdscrollbar:boolean)}
                    uninit:r
                    unset:{Record.adjoin GlobalUnsetType
                           r(1:unit
                             'class':unit
                             colormap:unit
                             container:unit
                             visual:unit
                             lrscrollbar:unit
                             tdscrollbar:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(1:unit
                             bitmap:unit
                             font:unit
                             lrscrollbar:unit
                             tdscrollbar:unit)})
         Child

      meth scrollframe(...)=M
         lock
            A B1 B
         in
            if {HasFeature M 1}==false then
               {Exception.raiseError qtk(missingParameter 1 self.widgetType M)}
            end
            {SplitParams M [1] A B1}
            B={PropagateLook B1}
            QTkClass,{Record.adjoin A init}
            Tk.canvas,{TkInit {Subtracts A [tdscrollbar lrscrollbar]}}
            %% B contains the structure of
            %% creates the children
            self.Child={MapLabelToObject {Record.adjoinAt B.1 parent self}}
            if {HasFeature B.1 feature} then
               self.((B.1).feature)=self.Child
            end
            if {HasFeature B.1 handle} then
               (B.1).handle=self.Child
            end
            {self tk(create window 0 0 anchor:nw window:self.Child)} % Displays the window
            %% update of the size of the child
            {self.Child tkBind(event:"<Configure>"
                               action:self#Resize)}
            {self Resize}
         end
      end

      meth Resize
         lock
            try
               W={ReturnTk unit winfo(width self.Child $) natural}
               H={ReturnTk unit winfo(height self.Child $) natural}
            in
               {self tk(configure scrollregion:q(0 0 W H))}
            catch _ then skip end
         end
      end

      meth destroy
         lock
            try {self.Child destroy} catch _ then skip end
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkScrollframe:QTkScrollframe)}

end
