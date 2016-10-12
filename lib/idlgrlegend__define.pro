; $Id: //depot/idl/releases/IDL_80/idldir/lib/idlgrlegend__define.pro#1 $
;
; Copyright (c) 1997-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; CLASS_NAME:
;   IDLgrLegend
;
; PURPOSE:
;   An IDLgrLegend object provides a simple interface for
;       displaying a list of glyph/box/styled line - text string
;       tuples.  They are displayed in a single column (default)
;       with an optional title string and bounding box which can
;       be filled.
;
; CATEGORY:
;   Graphics
;
; SUPERCLASSES:
;       This class inherits from IDLgrModel.
;
; SUBCLASSES:
;       This class has no subclasses.
;
; CREATION:
;       See IDLgrLegend::Init
;
; METHODS:
;       Intrinsic Methods
;       This class has the following methods:
;
;       IDLgrLegend::Cleanup
;       IDLgrLegend::ComputeDimensions
;       IDLgrLegend::Init
;       IDLgrLegend::GetProperty
;       IDLgrLegend::SetProperty
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/26/97
;-

;+
; =============================================================
;
; METHODNAME:
;       IDLgrLegend::Init
;
; PURPOSE:
;       The IDLgrLegend::Init function method initializes the
;       legend object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       Obj = OBJ_NEW('IDLgrLegend'[,aItemNames])
;
;       or
;
;       Result = oLegend->[IDLgrLegend::]Init([aItemNames])
;
; OPTIONAL INPUTS:
;       aItemNames - an array of strings to be used as the displayed
;               item labels.  The length of this array is used to
;               determine the number of items to be displayed.  Each
;               item is defined by taking one element from the
;               ITEM_NAME, ITEM_TYPE, ITEM_LINESTYLE, ITEM_THICK,
;               ITEM_COLOR and ITEM_OBJECT vectors.  IF the number
;               of items (as defined by the ITEM_NAME array) exceeds
;               any of the attribute vectors, the attribute defaults
;               will be used for any additional items.
;
; KEYWORD PARAMETERS:
;       BORDER_GAP(Get,Set): Set this keyword to a float value to indicate
;               the amount of blank space to be placed around the outside
;               of the glyphs and text items.  The units for this keyword
;               are in fraction of the legend label font height.  The
;               default is 0.1 (10% of the label font height).
;       COLUMNS(Get,Set): Set this keyword to an integer value to indicate
;               the number of columns the legend items should be displayed
;               in.  The default is 1.
;       FILL_COLOR(Get,Set): Set this keyword to the color to be used
;               to fill the legend background box.  The color may be
;               specified as a color lookup table index or as an RGB
;               vector.  The default is [255,255,255].
;       FONT(Get,Set): Set this keyword to an instance of an IDLgrFont
;               object class to describe the font to use to draw the
;               legend labels.  The default is 12 point Helvetica.
;               NOTE: If the default font is in use, retrieving the value
;               of the FONT property (using the GetProperty method)
;               will return a null object.
;       GAP(Get,Set): Set this keyword to a float value to indicate the
;               blank space to be placed vertically between each legend
;               item.  The units for this keyword are in fraction of the
;               legend label font height.  The default is 0.1 (10% of
;               the label font height).  This same gap is placed
;               horizontally between the legend glyph and the legend
;               text string.
;       GLYPH_WIDTH(Get,Set): Set this keyword to a float value to
;               indicate the width of the glyphs.  The units for this
;               keyword are a percentage of the font height.  The
;               default value is .8 (80%).
;       HIDE(Get,Set): Set this keyword to a boolean value to indicate
;               whether this object should be drawn. 0=Draw (default),
;               1=Hide.
;       ITEM_COLOR(Get,Set): Set this keyword to an array of colors
;               defining the color of each item.  This array can be of
;               the form [3,M] or [M] which defines M separate colors.
;               In the first case, the three values are used as an RGB
;               triplet, in the second case, the single value is used
;               as a color index value.  The default color is: [0,0,0].
;       ITEM_LINESTYLE(Get,Set): Set this keyword to an array of integers
;               defining the style of the line to be drawn if the TYPE
;               is 0.  The array can be of the form [M] or [2,M].  The
;               first form selects the linestyle for each legend item
;               from the predefined defaults:
;                    0=Solid line (the default)
;                    1=dotted
;                    2=dashed
;                    3=dash dot
;                    4=dash dot dot dot
;                    5=long dash
;                    6=no line drawn
;               The second form specifies the stippling pattern explicity
;               for each legend item (see IDLgrPolyline::Init LINESTYLE
;               keyword for details).
;       ITEM_NAME(Get,Set): Set this keyword to an array of strings.  This
;               keyword is the same as the aItemNames argument for the
;               IDLgrLegend::Init method.
;       ITEM_OBJECT(Get,Set): Set this keyword to an array of object
;               references.  These can be objects of type IDLgrSymbol
;               or IDLgrPattern.  A symbol object is drawn only if the
;               TYPE is 0.  A pattern object is used when drawing the
;               color patch if the TYPE is 1.  The default is the null
;               object.
;       ITEM_THICK(Get,Set): Set this keyword to an array of floats which
;               define the thickness of each item line (TYPE=0) in points.
;               The default is 1 point.
;       ITEM_TYPE(Get,Set): Set this keyword to an array of integers which
;               define the type of glyph to be displayed for each item.
;               0=line type (default), 1=filled box type.
;       NAME(Get,Set): Set this keyword to a string representing the name
;               to be associated with this object.  The default is the
;               null string, ''.
;       OUTLINE_COLOR(Get,Set): Set this keyword to the color to be used
;               to draw the legend outline box.  The color may be specified
;               as a color lookup table index or as an RGB vector.  The
;               default is [0,0,0].
;       OUTLINE_THICK(Get,Set): Set this keyword to an integer which defines
;               the thickness of the legend outline box.  Default = 1 point.
;       SHOW_OUTLINE(Get,Set): Set this keyword to a boolean value indicating
;               whether the outline box should be displayed.  0=Do not
;               display outline (default), 1=Display outline.
;       SHOW_FILL(Get,Set): Set this keyword to a boolean value indicating
;               whether the background should be filled with a color. 0=Do not
;               fill background (default), 1=fill background.
;       TEXT_COLOR(Get,Set): Set this keyword to the color to be used to
;               draw the legend item text.  The color may be specified
;               as a color lookup table index or as an RGB vector.  The
;               default is [0,0,0].
;       TITLE(Get,Set): Set this keyword to an instance of the IDLgrText
;               object class to specify the title for the legend.  The
;               default is the null object, specifying that no title is
;               drawn.  The title will be centered at the top of the
;               legend, even if the text object itself has an associated
;               location.
;       UVALUE(Get,Set): Set this keyword to a value of any type.  You
;               may use this value to contain any information you wish.
;       XCOORD_CONV(Get,Set): Set this keyword to a vector, [t,s],
;               indicating the translation and scaling to be applied
;               to convert the X coordinates to an alternate data space.
;               The formula for the conversion is as follows:
;               converted X = t + s*X.  The default is [0,1].
;       YCOORD_CONV(Get,Set): Set this keyword to a vector, [t,s],
;               indicating the translation and scaling to be applied
;               to convert the Y coordinates to an alternate data space.
;               The formula for the conversion is as follows:
;               converted Y = t + s*Y.  The default is [0,1].
;       ZCOORD_CONV(Get,Set): Set this keyword to a vector, [t,s],
;               indicating the translation and scaling to be applied
;               to convert the Y coordinates to an alternate data space.
;               The formula for the conversion is as follows:
;               converted Y = t + s*Y.  The default is [0,1].
; OUTPUTS:
;       1: successful, 0: unsuccessful.
;
; EXAMPLE:
;       oLegend = OBJ_NEW('IDLgrLegend')
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/26/97
;-

FUNCTION IDLgrLegend::Init, aItemNames, BORDER_GAP = Border_Gap, $
                    COLUMNS = Columns, FILL_COLOR = Fill_Color, $
                    FONT = Font, GAP = Gap, GLYPH_WIDTH = glyphWidth, $
                    HIDE = Hide, ITEM_COLOR = Item_Color, $
                    ITEM_LINESTYLE = Item_Linestyle, ITEM_NAME = Item_Name, $
                    ITEM_OBJECT = Item_Object, ITEM_THICK = Item_Thick, $
                    ITEM_TYPE = Item_Type, ITEM_RGB = Item_RGB, NAME = Name, $
                    OUTLINE_COLOR = Outline_Color, $
                    OUTLINE_THICK = Outline_Thick, $
                    SHOW_OUTLINE = Show_Outline, $
                    SHOW_FILL = Show_Fill, TEXT_COLOR = Text_Color, $
                    TITLE = Title, UVALUE = Uvalue,$
                    XCOORD_CONV = Xcoord_Conv, YCOORD_CONV = Ycoord_Conv, $
                    ZCOORD_CONV = Zcoord_Conv, _EXTRA = e

  compile_opt idl2, hidden
  ON_ERROR, 2

    CATCH, Error_Status
    if (Error_Status ne 0) then begin
    print,error_status
        if (OBJ_VALID(self.oScaleNode)) then $
        OBJ_DESTROY, self.oScaleNode
        if (OBJ_VALID(self.oOutline)) then $
        OBJ_DESTROY, self.oOutline
        if (OBJ_VALID(self.oFill)) then $
        OBJ_DESTROY, self.oFill
        if (OBJ_VALID(self.oFont)) then $
        OBJ_DESTROY, self.oFont
    if (PTR_VALID(self.pItem_Color)) then $
        PTR_FREE, self.pItem_Color
    if (PTR_VALID(self.pItem_Linestyle)) then $
        PTR_FREE, self.pItem_Linestyle
    if (PTR_VALID(self.pItem_Name)) then $
        PTR_FREE, self.pItem_Name
    if (PTR_VALID(self.pItem_Object)) then $
        PTR_FREE, self.pItem_Object
    if (PTR_VALID(self.pItem_Thick)) then $
        PTR_FREE, self.pItem_Thick
    if (PTR_VALID(self.pItem_Type)) then $
        PTR_FREE, self.pItem_Type
    if (PTR_VALID(self.pText_Color)) then $
        PTR_FREE, self.pText_Color
    if (PTR_VALID(self.pGlyphs)) then $
        PTR_FREE, self.pGlyphs
    if (PTR_VALID(self.pTexts)) then $
        PTR_FREE, self.pTexts
    if (PTR_VALID(self.cleanLeave)) then $
        PTR_FREE, self.cleanLeave
    if (PTR_VALID(self.cleanGlyphs)) then $
        PTR_FREE, self.cleanGlyphs
        return, 0
    endif

    if (self->IDLgrModel::Init(_EXTRA=e) ne 1) then RETURN, 0
    self->IDLgrModel::SetProperty, /SELECT_TARGET
    if (KEYWORD_SET(Hide)) then self->IDLgrModel::SetProperty, Hide=1

    ;; First, I need to figure out what color mode I should be in
    if (N_ELEMENTS(Item_Color) gt 0) then begin
        if (N_ELEMENTS(Item_RGB) gt 0) then $
          self.colorMode = 1 - KEYWORD_SET(Item_RGB) $
        else if (size(Item_Color,/N_DIMENSIONS) eq 1) then $
          self.colorMode = 1 $
        else $
          self.colorMode = 0
    endif

    self.cleanLeave = PTR_NEW(OBJ_NEW())
    self.cleanGlyphs = PTR_NEW(OBJ_NEW())

    self.pGlyphs = PTR_NEW(0)
    self.pTexts = PTR_NEW(0)

    ; This node will allow scaling of all the sub objects
    self.oScaleNode = OBJ_NEW('IDLgrModel', LIGHTING=0)

    if (N_ELEMENTS(aItemNames) le 0) then $
      aItemNames = ''

    numTags = N_ELEMENTS(Item_Name)
    if (numTags le 0) then begin
        Item_Name = aItemNames
        numTags = N_ELEMENTS(aItemNames)
    endif

    if (size(Item_Name,/TYPE) ne 7) then begin
        MESSAGE,'ITEM_NAME not of type string.'
        RETURN, 0
    endif

    if (N_ELEMENTS(Border_Gap) le 0) then begin
        Border_Gap = 0.1
    endif

    if (N_ELEMENTS(glyphWidth) le 0) then begin
        glyphWidth = 0.8
    endif

    if (N_ELEMENTS(Columns) le 0) then begin
        Columns = 1
    endif $
    else begin
        if (Columns le 0) then begin
            MESSAGE,'Out of range error: COLUMNS'
            RETURN, 0
        endif
    endelse

    if (N_ELEMENTS(Fill_Color) le 0) then begin
        Fill_Color = [255,255,255]
    endif

    if (N_ELEMENTS(Font) gt 0) then begin
        if (not OBJ_ISA(Font, 'IDLgrFont')) then begin
            MESSAGE,'Unable to convert variable to type object reference.'
            RETURN, 0
        endif
    endif else begin
        Font = OBJ_NEW('IDLgrFont')
        (*self.cleanLeave) = [(*self.cleanLeave),Font]
    endelse

    if (N_ELEMENTS(Gap) le 0) then $
      Gap = 0.1

    if (N_ELEMENTS(Item_Color) le 0) then begin
        Item_Color = [0,0,0]
        self.colorMode = 0
    endif

    if (N_ELEMENTS(Item_Linestyle) le 0) then $
      Item_Linestyle = 0

    if (N_ELEMENTS(Item_Object) gt 0) then begin
        for index = 0,N_ELEMENTS(Item_Object)-1 do begin
            ; Test for valid inputs - Symbol, Pattern, Null
            if (not (OBJ_ISA(Item_Object[index],'IDLgrSymbol') or $
                     OBJ_ISA(Item_Object[index],'IDLgrPattern') or $
                     Item_Object[index] eq OBJ_NEW() $
                    ) $
               ) then begin
                MESSAGE,'Unable to convert variable to type object reference.'
                RETURN, 0
            endif
        endfor
   endif else begin
       Item_Object = OBJ_NEW()
       (*self.cleanGlyphs) = [(*self.cleanGlyphs),Item_Object]
   endelse

    if (N_ELEMENTS(Item_Thick) le 0) then $
      Item_Thick = 1

    if (N_ELEMENTS(Item_Type) le 0) then $
      Item_Type = 0

    if (N_ELEMENTS(Name) gt 0) then $
      self->IDLgrModel::SetProperty, Name = Name

    if (N_ELEMENTS(Outline_Color) le 0) then begin
        Outline_Color = [0,0,0]
    endif

    if (N_ELEMENTS(Outline_Thick) le 0) then $
      Outline_Thick = 1

    if (not KEYWORD_SET(Show_Outline)) then $
      Show_Outline = 0

    if (not KEYWORD_SET(Show_Fill)) then $
      Show_Fill = 0

    if (N_ELEMENTS(Text_Color) le 0) then begin
        Text_Color = [0,0,0]
    endif

    if (N_ELEMENTS(Title) gt 0) then begin
        if (not OBJ_ISA(Title, 'IDLgrText')) then begin
            MESSAGE,'Unable to convert variable to type object reference.'
            RETURN, 0
        endif
    endif else begin
        Title = OBJ_NEW()
       (*self.cleanLeave) = [(*self.cleanLeave),Title]
    endelse

    if (N_ELEMENTS(Uvalue) gt 0) then $
      self->IDLgrModel::SetProperty, UVALUE = Uvalue

    ; store the state of this object
    if (FINITE(Border_Gap)) then $
      self.Border_Gap = Border_Gap $
    else begin
        MESSAGE, 'Infinite or invalid (NaN) operands not allowed.',/info
        return, 0
    endelse

    if (FINITE(Columns)) then $
      self.Columns = Columns $
    else begin
        MESSAGE,'Infinite or invalid (NaN) operands not allowed.',/info
        return, 0
    endelse

    if (FINITE(Gap)) then $
      self.Gap = Gap $
    else begin
        MESSAGE, 'Infinite or invalid (NaN) operands not allowed.',/info
        return, 0
    endelse

    if (FINITE(glyphWidth)) then $
      self.glyphWidth = glyphWidth $
    else begin
        MESSAGE, 'Infinite or invalid (NaN) operands not allowed.',/info
        return, 0
    endelse

    self.oFont = Font
    self.oTitle = Title
    self.pText_Color = PTR_NEW(Text_Color)
    self.pItem_Color = PTR_NEW(Item_Color)
    self.pItem_LineStyle = PTR_NEW(Item_Linestyle)
    self.pItem_Name = PTR_NEW(Item_Name)
    self.pItem_Object = PTR_NEW(Item_Object)
    self.pItem_Thick = PTR_NEW(Item_Thick)
    self.pItem_Type = PTR_NEW(Item_Type)

    ; Now, set up the arrays to hold defaults where necessary.
    ; This is complicated, but necessary.  If the user doesn't
    ; specify enough elements for any of the keywords, defaults
    ; are used.  numTags is the number of elements in aItemNames
    self->DefaultArrays

    ; Coordinate conversion.
    transform = [[1.0,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
    if(N_ELEMENTS(Xcoord_Conv) gt 0) then begin
        transform[0,0] = Xcoord_Conv[1]
        transform[3,0] = Xcoord_Conv[0]
    endif
    if(N_ELEMENTS(Ycoord_Conv) gt 0) then begin
        transform[1,1] = Ycoord_Conv[1]
        transform[3,1] = Ycoord_Conv[0]
    endif
    if(N_ELEMENTS(Zcoord_Conv) gt 0) then begin
        transform[2,2] = Zcoord_Conv[1]
        transform[3,2] = Zcoord_Conv[0]
    endif
    self.oScaleNode->SetProperty, TRANSFORM = transform

    ; Create the polyline (Outline)
    self.oOutline = OBJ_NEW('IDLgrPolyline', HIDE = (1-Show_Outline), $
                         COLOR = Outline_Color, THICK = Outline_Thick)

    ; Create the polygon (Fill)
    self.oFill = OBJ_NEW('IDLgrPolygon', HIDE = (1-Show_Fill), $
                         COLOR = Fill_Color)

    ; Add everything needed to the state
    self->Add, self.oScaleNode

    ; Note: the oFill object should be added before any Text objects
    ;       as the blended outlines will be erased by the backing polygon
    ;       if it is drawn after the Text objects.  This is because the
    ;       blended outlines are drawn w/Zbuffer test enabled, but Zbuffer
    ;       write disabled.
    self.oScaleNode->Add,self.oOutline
    self.oScaleNode->Add,self.oFill

    if (self.oTitle ne OBJ_NEW()) then $
      self.oScaleNode->Add,self.oTitle

    ; Call a private method to determine sizing and spacing
    self->CreateGlyphs

    self.bRecompute = 1

    RETURN, 1
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrLegend::DefaultArrays
;
; PURPOSE:
;       The IDLgrLegend::DefaultArrays procedure method is a private
;       method and is not intended to be called directly.
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/30/97
;-

pro IDLgrLegend::DefaultArrays

  compile_opt idl2, hidden
  ON_ERROR, 2

  Item_Color = (*self.pItem_Color)
  Item_Linestyle = (*self.pItem_Linestyle)
  Item_Name = (*self.pItem_Name)
  Item_Object = (*self.pItem_Object)
  Item_Thick = (*self.pItem_Thick)
  Item_Type = (*self.pItem_Type)

  numTags = N_ELEMENTS(Item_Name)

  if (self.colorMode) then begin
      ;; color index
      if (size(Item_Color,/N_ELEMENTS) le numTags) then begin
          Item_Color_tmp = intarr(numTags)
          Item_Color_tmp[*] = 0
          Item_Color_tmp[0] = Item_Color
          Item_Color = Item_Color_tmp
      endif
  endif $
  else begin
      ;; RGB
      fillInFlag = 1
      if (size(Item_Color, /N_DIMENSIONS) gt 1) then begin
          if ((size(Item_Color,/DIMENSIONS))[1] gt numTags) then $
            fillInFlag = 0
      endif $
      else $
        Item_Color = REFORM(Item_Color, 3, 1)

      if (fillInFlag) then begin
          Item_Color_tmp = intarr(3,numTags)
          Item_Color_tmp[*,*] = 0
          Item_Color_tmp[*,0:(size(Item_Color,/DIMENSIONS))[1]-1]=$
            Item_Color
          Item_Color = Item_Color_tmp
      endif
  endelse

  if (size(Item_Linestyle,/N_DIMENSIONS) le 1) then begin
      ;; predefined
      if (size(Item_Linestyle,/N_ELEMENTS) le numTags) then begin
          Item_Linestyle_tmp = intarr(numTags)
          Item_Linestyle_tmp[0] = Item_Linestyle
          Item_Linestyle = Item_Linestyle_tmp
      endif
  endif $
  else begin
      ;; stippling pattern given
      if ((size(Item_Linestyle,/DIMENSIONS))[1] le numTags) then begin
          Item_Linestyle_tmp = lonarr(2,numTags)
          Item_Linestyle_tmp[0,*] = $
            Item_Linestyle[0,(size(Item_Linestyle,/DIMENSIONS))[1]-1]
          Item_Linestyle_tmp[1,*] = $
            Item_Linestyle[1,(size(Item_Linestyle,/DIMENSIONS))[1]-1]
          Item_Linestyle_tmp[*,0:(size(Item_Linestyle,/DIMENSIONS))[1]-1] = $
            Item_Linestyle
          Item_Linestyle = Item_Linestyle_tmp
      endif
  endelse

  if (N_ELEMENTS(Item_Object) le numTags) then begin
      Item_Object_tmp = OBJARR(numTags)
      for index = N_ELEMENTS(Item_Object), numTags-1 do $
        (*self.cleanLeave) = [*self.cleanLeave, Item_Object_tmp[index]]
      Item_Object_tmp[0] = Item_Object
      Item_Object = Item_Object_tmp
  endif

  if (N_ELEMENTS(Item_Thick) le numTags) then begin
      Item_Thick_tmp = fltarr(numTags)
      Item_Thick_tmp[*] = 1.0
      Item_Thick_tmp[0] = Item_Thick
      Item_Thick = Item_Thick_tmp
  endif

  if (N_ELEMENTS(Item_Type) le numTags) then begin
      Item_Type_tmp = intarr(numTags)
      Item_Type_tmp[0] = Item_Type
      Item_Type = Item_Type_tmp
  endif

  *self.pItem_Color = Item_Color
  *self.pItem_LineStyle = Item_Linestyle
  *self.pItem_Name = Item_Name
  *self.pItem_Object = Item_Object
  *self.pItem_Thick = Item_Thick
  *self.pItem_Type = Item_Type

end

;+
; =============================================================
;
; METHODNAME:
;       IDLgrLegend::CreateGlyphs
;
; PURPOSE:
;       The IDLgrLegend::CreateGlyphs procedure method is a private
;       method and is not intended to be called directly.
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/30/97
;-

pro IDLgrLegend::CreateGlyphs

  compile_opt idl2, hidden
  ON_ERROR, 2

  ; Cleanup all the glyphs and texts I made
  for index = 0, N_ELEMENTS(*self.cleanGlyphs)-1 do begin
      if (self.oScaleNode->IsContained((*self.cleanGlyphs)[index])) then $
        self.oScaleNode->Remove, (*self.cleanGlyphs)[index]
      OBJ_DESTROY, (*self.cleanGlyphs)[index]
  endfor

  ; This is necessary for re-initialization of the heap variable
  PTR_FREE, self.cleanGlyphs
  self.cleanGlyphs = PTR_NEW(OBJ_NEW())

  ; init the main object arrays
  *self.pGlyphs = OBJARR(N_ELEMENTS(*self.pItem_Name))
  *self.pTexts = OBJARR(N_ELEMENTS(*self.pItem_Name))

  ; Loop through all the names given
  for index = 0, N_ELEMENTS((*self.pItem_Name))-1 do begin
      if ((*self.pItem_Type)[index] eq 0) then begin
          if (OBJ_ISA((*self.pItem_Object)[index],'IDLgrSymbol') or $
              ((*self.pItem_Object)[index] eq OBJ_NEW())) then begin
              if (self.colorMode) then $
                color = (*self.pItem_Color)[index] $
              else $
                color = (*self.pItem_Color)[*,index]
;              if (SIZE((*self.pItem_Color),/N_DIMENSIONS) eq 2) then $
;                color = (*self.pItem_Color)[*,index] $
;              else $
;                color = (*self.pItem_Color)[index]
              (*self.pGlyphs)[index] = $
                OBJ_NEW('IDLgrPolyline', COLOR = color, $
                        LINESTYLE = (*self.pItem_Linestyle)[index], $
                        THICK = (*self.pItem_Thick)[index], $
                        SYMBOL = (*self.pItem_Object)[index])
              (*self.cleanGlyphs)=[(*self.cleanGlyphs),(*self.pGlyphs)[index]]
          endif $
          else begin
              MESSAGE,'ITEM_OBJECT type incompatible with ITEM_TYPE'
          endelse
      endif $
      else begin
          if (self.colorMode) then $
            color = (*self.pItem_Color)[index] $
          else $
            color = (*self.pItem_Color)[*,index]
;          if (SIZE((*self.pItem_Color),/N_DIMENSIONS) eq 2) then $
;            color = (*self.pItem_Color)[*,index] $
;          else $
;            color = (*self.pItem_Color)[index]
          if (OBJ_ISA((*self.pItem_Object)[index],'IDLgrPattern') or $
              ((*self.pItem_Object)[index] eq OBJ_NEW())) then begin
              (*self.pGlyphs)[index] = OBJ_NEW('IDLgrPolygon',$
                                  COLOR = color, $
                                  FILL_PATTERN = (*self.pItem_Object)[index])
              (*self.cleanGlyphs)=[(*self.cleanGlyphs),(*self.pGlyphs)[index]]
          endif $
          else begin
              MESSAGE,'ITEM_OBJECT type incompatible with ITEM_TYPE'
          endelse
      endelse
      (*self.pTexts)[index] = OBJ_NEW('IDLgrText', $
                                      /ENABLE_FORMATTING, $  ; allow Hershey codes
                                      FONT = self.oFont, $
                                      COLOR = (*self.pText_Color), $
                                      STRINGS = (*self.pItem_Name)[index],$
                                      RECOMPUTE_DIMENSIONS = 2)
      (*self.cleanGlyphs) = [(*self.cleanGlyphs),(*self.pTexts)[index]]
      self.oScaleNode->Add,(*self.pGlyphs)[index]
      self.oScaleNode->Add,(*self.pTexts)[index]
  endfor
end

;+
; =============================================================
;
; METHODNAME:
;       IDLgrLegend::ComputeDimensions
;
; PURPOSE:
;       The IDLgrLegend::ComputeDimensions method function
;       computes and returns the dimensions of the legend
;       for a given destination.
;
; CALLING SEQUENCE:
;       Result = oLegend->[IDLgrLegend::]ComputeDimensions(SrcDest)
;
; INPUTS:
;       SrcDest - A destination object.
;
; EXAMPLE:
;       dimensions = oLegend->ComputeDimensions(oSrcDest)
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 10/17/97
;-

function IDLgrLegend::ComputeDimensions, oSrcDest, PATH=aliasPath

  compile_opt idl2, hidden
  ON_ERROR, 2

    if (self.bRecompute) then begin
        ; Move up the tree in search of a view.  If available, we will
        ; use the Z clipping range of the view to compute the smallest
        ; possible depth offset that will ensure that foreground
        ; objects are in front of the fill polygon without overlap.
        oView = OBJ_NEW()
        self->IDLgrLegend::GetProperty, PARENT=oParent
        while (OBJ_VALID(oParent)) do begin
            if (OBJ_ISA(oParent, 'IDLgrView')) then begin
                oView = oParent
                oParent = OBJ_NEW()
            endif else begin
                oChild = oParent
                oChild->GetProperty, PARENT=oParent
            endelse
        endwhile

        if (OBJ_VALID(oView)) then begin
            oView->IDLgrView::GetProperty, ZCLIP = zClip
            depthOffset = (double(zClip[0]) - double(zClip[1]))/65536.d
        endif else begin
            depthOffset = 0.0005
        endelse

        maxTags = N_ELEMENTS((*self.pItem_Name))
        descFix = dblarr(maxTags)

        if (self.Columns gt maxTags) then $
          self.Columns = maxTags

        ;; array to keep track of the max column widths
        textWidths = fltarr(self.Columns)
        textHeight = 0.0

        colIndex = 0
        for index = 0, maxTags-1 do begin
            ;; if we've reached the last column, start over
            if (colIndex eq self.Columns) then colIndex = 0

            (*self.pTexts)[index]->SetProperty, CHAR_DIMENSIONS = [0,0]

            textDims = oSrcDest->GetTextDimensions((*self.pTexts)[index], $
                                                  DESCENT = descenders, $
                          PATH = aliasPath)

            ;; If larger, replace
            textWidths[colIndex] = textWidths[colIndex] > textDims[0]

            descFix[index] = ABS(descenders)

            textHeight = textHeight > textDims[1]
            colIndex = colIndex + 1
        endfor

        (*self.pTexts)[0]->GetProperty, CHAR_DIMENSIONS = charDims

        vAspectRatio = 1.0
        hAspectRatio = 1.0

        if (charDims[0] gt charDims[1]) then begin
            hAspectRatio = charDims[0]/charDims[1]
        endif $
        else begin
            hAspectRatio = charDims[0]/charDims[1]
        endelse

        maxWidth = TOTAL(textWidths)
        hglyphWidth = textHeight*0.8 * hAspectRatio
        vglyphWidth = textHeight*0.8 * vAspectRatio
        colGlyphWidth = textHeight * self.glyphWidth * hAspectRatio
        self.hGlyphWidth = hglyphWidth
        self.vGlyphWidth = vglyphWidth
        hgap = self.Gap * textHeight * hAspectRatio
        vgap = self.Gap * textHeight * vAspectRatio
        colWidths = textWidths + colGlyphWidth + hgap
        hborderGap = self.Border_Gap * textHeight * hAspectRatio
        vborderGap = self.Border_Gap * textHeight * vAspectRatio
        glyphGap = textHeight*0.1*vAspectRatio

        ;; This determines the max number of rows
        maxVertElems = float(maxTags)/self.Columns
        if (maxVertElems gt fix(maxVertElems)) then $
          maxVertElems = fix(maxVertElems + 1.0)

        ;; Get the dimensions of the box
        boxVert = ((vborderGap*2.0) + $ ; outside gap
                   (maxVertElems * textHeight) + $ ; total height of text
                   (vgap*(maxVertElems-1))) ; gaps between text

        boxHorz = ((hborderGap*2.0) + $ ; outside gap
                   ((self.Columns-1.0)*hgap) + $
                   TOTAL(colWidths))

        ;; space for title?
        if (self.oTitle ne OBJ_NEW()) then begin
            self.oTitle->SetProperty, CHAR_DIMENSIONS = [0,0]
            titleDims = oSrcDest->GetTextDimensions(self.oTitle, PATH=aliasPath)
            boxVert = boxVert + titleDims[1] + vgap
            boxHorz = boxHorz > titleDims[0]
        endif

        ;; Set the box dimensions
        self.oOutline->SetProperty, Data = [[0,0,0],$
                                            [boxHorz,0,0],$
                                            [boxHorz,boxVert,0],$
                                            [0,boxVert,0],$
                                            [0,0,0]]

        ;; Set the fill dimensions
        self.oFill->SetProperty, Data = [[0,0,-depthOffset],$
                                         [boxHorz,0,-depthOffset],$
                                         [boxHorz,boxVert,-depthOffset],$
                                         [0,boxVert,-depthOffset],$
                                         [0,0,-depthOffset]]

        ;; Now to position the glyphs and text
        modOffset = maxTags mod self.Columns
        startIndex = (maxTags - modOffset) < maxTags
        if (startIndex eq maxTags) then startIndex = startIndex - 1
        ;; perfect fit
        if (modOffset eq 0) then startIndex = maxTags - self.Columns

        endIndex = maxTags - 1
        leftStart = hborderGap
        bottomStart = vborderGap

        ;; This loop determines the placement of the glyphs and text
        ;; It places them from left to right, bottom to top
        ;; Since the user enters their strings to be placed left to right,
        ;; top to bottom, a little work is needed to place correctly
        repeat begin
            for index = startIndex,endIndex do begin
                if ((*self.pItem_Type)[index] eq 0) then begin
                    symArr = OBJARR(3)
                    (*self.pGlyphs)[index]->GetProperty, SYMBOL = oSym
                    tmpSym = OBJ_NEW('IDLgrSymbol',0)
                    (*self.cleanGlyphs) = [(*self.cleanGlyphs),tmpSym]
                    symArr[0] = (symArr[2] = tmpSym)
                    if (N_ELEMENTS(oSym) gt 1) then $
                      oSym = oSym[1]
                    if (oSym ne OBJ_NEW()) then $
                      symArr[1] = oSym $
                    else $
                      symArr[1] = tmpSym
                    (*self.pGlyphs)[index]->SetProperty, $
                      DATA = [[leftStart,$
                               bottomStart+(textHeight/2.0)],$
                              [leftStart+(colGlyphWidth/2.0), $
                               bottomStart+(textHeight/2.0)], $
                              [leftStart+colGlyphWidth, $
                               bottomStart+(textHeight/2.0)]], $
                      SYMBOL = symArr
                endif else begin
                    (*self.pGlyphs)[index]->SetProperty, $
                  DATA = [[leftStart, bottomStart+glyphGap],$
                          [leftStart+colGlyphWidth, bottomStart+glyphGap], $
                          [leftStart+colGlyphWidth, $
                           bottomStart+vglyphWidth+glyphGap], $
                          [leftStart, bottomStart+vglyphWidth+glyphGap], $
                          [leftStart, bottomStart+glyphGap]]
                endelse
                leftStart = leftStart + hgap + colGlyphWidth

                ;; Now place the text
                (*self.pTexts)[index]->SetProperty, $
                  LOCATIONS = [leftStart, bottomStart+MAX(descFix)]
                ;; next column
                leftStart = leftStart + textWidths[index-startIndex] + hgap
            endfor
            bottomStart = bottomStart + textHeight + vgap
            leftStart = hborderGap
            endIndex = startIndex - 1
            startIndex = startIndex - self.Columns
        endrep until startIndex lt 0

        ;; Check for title placement
        if (self.oTitle ne OBJ_NEW()) then begin
            leftStart = (boxHorz-titleDims[0])/2.0
            self.oTitle->SetProperty,LOCATIONS = [leftStart,bottomStart]
        endif

    endif

    self->IDLgrLegend::GetProperty, XRANGE = xRange, YRANGE = yRange, $
                                    ZRANGE = zRange

    self.bRecompute = 0

    return, [xRange[1]-xrange[0], yRange[1]-yrange[0], 0]
end

;+
; =============================================================
;
; METHODNAME:
;       IDLgrLegend::Draw
;
; PURPOSE:
;       The IDLgrLegend::Draw procedure method is a private
;       method and is not to be called directly.
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 10/1/97
;-

pro IDLgrLegend::Draw, oSrcDest, oView

  compile_opt idl2, hidden
  ON_ERROR, 2

    result = self->ComputeDimensions(oSrcDest)

    ;; Saving the original symbol size so I don't
    ;; corrupt the symbol the user gave me
    ;; I'm going to change it, but then change it
    ;; back at the end of the over-ridden draw
    maxTags = N_ELEMENTS((*self.pItem_Name))
    originalSymSizes = fltarr(2,maxTags)

    for index = 0, maxTags-1 do begin
        if (OBJ_ISA((*self.pGlyphs)[index], 'IDLgrPolyline')) then begin
            (*self.pGlyphs)[index]->GetProperty, SYMBOL = symArr
            if (N_ELEMENTS(symArr) gt 1) then begin
                oSym = symArr[1]
                oSym->GetProperty, SIZE = originalSymSize
                originalSymSizes[*,index] = originalSymSize[0:1]
                oSym->SetProperty, $
                  SIZE=[self.hGlyphWidth/2.0,self.vGlyphWidth/2.0]
            endif
        endif
    endfor

    self->IDLgrModel::Draw, oSrcDest, oView

    ;; fixing symbol sizes I changed earlier
;    sizeCheck = size(originalSymSizes,/N_DIMENSIONS)
;    if (sizeCheck eq 2) then begin
        for index = 0, maxTags-1 do begin
            if (originalSymSizes[0,index] ne 0) then begin
                (*self.pGlyphs)[index]->GetProperty, SYMBOL = symArr
                if (N_ELEMENTS(symArr) gt 1) then begin
                    oSym = symArr[1]
                    oSym->SetProperty, SIZE = originalSymSizes[*,index]
                endif
            endif
        endfor
;    endif
end

;+
; =============================================================
;
; METHODNAME:
;       IDLgrLegend::Cleanup
;
; PURPOSE:
;       The IDLgrLegend::Cleanup procedure method preforms all cleanup
;       on the object.
;
;       NOTE: Cleanup methods are special lifecycle methods, and as such
;       cannot be called outside the context of object destruction.  This
;       means that in most cases, you cannot call the Cleanup method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Cleanup method
;       from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;       OBJ_DESTROY, oLegend
;
;       or
;
;       oLegend->[IDLgrLegend::]Cleanup
;
; INPUTS:
;       There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;       There are no keywords for this method.
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/26/97
;-

PRO IDLgrLegend::Cleanup

  compile_opt idl2, hidden
  ON_ERROR, 2

    ; Cleanup all the glyphs and texts I made
    for index = 0, N_ELEMENTS(*self.cleanLeave)-1 do begin
        OBJ_DESTROY, (*self.cleanLeave)[index]
    endfor

    for index = 0, N_ELEMENTS(*self.cleanGlyphs)-1 do begin
        OBJ_DESTROY, (*self.cleanGlyphs)[index]
    endfor

    if self.oScaleNode->isContained(self.oTitle) then begin
          self.oScaleNode->Remove, self.oTitle
    endif

    OBJ_DESTROY,self.oOutline
    OBJ_DESTROY,self.oFill
    OBJ_DESTROY,self.oScaleNode

    PTR_FREE,self.pItem_Color, self.pItem_Name, self.pItem_Object, $
      self.pItem_Thick, self.pItem_Type, self.pText_Color, self.pGlyphs, $
      self.pTexts, self.cleanLeave, self.pItem_Linestyle, self.cleanGlyphs

    ; Cleanup the superclass.
    self->IDLgrModel::Cleanup
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrLegend::SetProperty
;
; PURPOSE:
;       The IDLgrLegend::SetProperty procedure method sets the value
;       of a property or group of properties for the legend.
;
; CALLING SEQUENCE:
;       oLegend->[IDLgrLegend::]SetProperty
;
; INPUTS:
;       There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;       Any keyword to IDLgrLegend::Init followed by the word "Set"
;       can be set using IDLgrLegend::SetProperty.
;
; EXAMPLE:
;       myLegend->SetProperty, NAME = 'My Legend'
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/26/97
;-

PRO IDLgrLegend::SetProperty, BORDER_GAP = Border_Gap, $
               COLUMNS = Columns, FILL_COLOR = Fill_Color, $
               FONT = Font, GAP = Gap, $
               GLYPH_WIDTH = glyphWidth, $
               ITEM_COLOR = Item_Color, $
               ITEM_LINESTYLE = Item_Linestyle, ITEM_NAME = Item_Name, $
               ITEM_OBJECT = Item_Object, ITEM_THICK = Item_Thick, $
               ITEM_TYPE = Item_Type, $
               ITEM_RGB = Item_RGB, RECOMPUTE = recompute, $
               OUTLINE_COLOR = Outline_Color, $
               OUTLINE_THICK = Outline_Thick, $
               SHOW_OUTLINE = Show_Outline, $
               SHOW_FILL = Show_Fill, TEXT_COLOR = Text_Color, $
               TITLE = Title, $
               XCOORD_CONV = Xcoord_Conv, YCOORD_CONV = Ycoord_Conv, $
               ZCOORD_CONV = Zcoord_Conv, _EXTRA = e

  compile_opt idl2, hidden
  ON_ERROR, 2

    ; Pass along extraneous keywords to the superclass
    self->IDLgrModel::SetProperty, _EXTRA=e

    if (N_ELEMENTS(Show_Outline) ne 0) then $
      self.oOutline->SetProperty, HIDE = (1-KEYWORD_SET(Show_Outline))

    if (N_ELEMENTS(Show_Fill) ne 0) then $
      self.oFill->SetProperty, HIDE = (1-KEYWORD_SET(Show_Fill))

    if (N_ELEMENTS(Title) gt 0) then begin
        if (OBJ_ISA(Title, 'IDLgrText') or (Title eq OBJ_NEW())) then begin
            if (OBJ_VALID(self.oTitle)) then begin
                self.oScaleNode->Remove, self.oTitle
            endif
            self.oTitle = Title
            if (OBJ_VALID(self.oTitle)) then $
              self.oScaleNode->Add,self.oTitle
        endif else $
          MESSAGE,'Unable to convert variable to type object reference.',/info
        self.bRecompute = 1
    endif

    if (N_ELEMENTS(Border_Gap) gt 0) then begin
        if (FINITE(Border_Gap)) then $
          self.Border_Gap = Border_Gap $
        else $
          MESSAGE,'Infinite or invalid (NaN) operands not allowed.',/info
        self.bRecompute = 1
    endif

    if (N_ELEMENTS(Columns) gt 0) then begin
        if (FINITE(Columns)) then begin
            if (Columns ge 1) then $
              self.Columns = Columns $
            else $
              MESSAGE, 'Out of range error: COLUMNS',/ info
        endif $
        else $
          MESSAGE,'Infinite or invalid (NaN) operands not allowed.',/info
        self.bRecompute = 1
    endif

    if (N_ELEMENTS(Fill_Color) gt 0) then $
      self.oFill->SetProperty, COLOR = Fill_Color

    if (N_ELEMENTS(Font) gt 0) then begin
        if (not OBJ_ISA(Font, 'IDLgrFont')) then $
          MESSAGE,'Unable to convert variable to type object reference.',$
          /info $
        else begin
            self.oFont = Font
            self.bRecompute = 1
        endelse
    endif

    if (N_ELEMENTS(Gap) gt 0) then begin
        if (FINITE(Gap)) then $
          self.Gap = Gap $
        else $
          MESSAGE,'Infinite or invalid (NaN) operands not allowed.',/info
        self.bRecompute = 1
    endif

    if (N_ELEMENTS(glyphWidth) gt 0) then begin
        if (FINITE(glyphWidth)) then $
          self.glyphWidth = glyphWidth $
        else $
          MESSAGE,'Infinite or invalid (NaN) operands not allowed.',/info
        self.bRecompute = 1
    endif

    if (N_ELEMENTS(Item_Color) gt 0) then begin
        if (N_ELEMENTS(Item_RGB) gt 0) then $
          self.colorMode = Item_RGB
        *self.pItem_Color = Item_Color
        self.bRecompute = 1
    endif

    if (N_ELEMENTS(Item_Linestyle) gt 0) then begin
        *self.pItem_Linestyle = Item_Linestyle
        self.bRecompute = 1
    endif

    if (N_ELEMENTS(Item_Name) gt 0) then begin
        if (size(Item_Name,/TYPE) ne 7) then $
          MESSAGE, 'ITEM_NAME not of type string.' $
        else begin
            *self.pItem_Name = Item_Name
            self.bRecompute = 1
        endelse
    endif

    convertError = 0
    if (N_ELEMENTS(Item_Object) gt 0) then begin
        for index = 0,N_ELEMENTS(Item_Object)-1 do begin
            if (OBJ_VALID(Item_Object[index])) then begin
                if (not (OBJ_ISA(Item_Object[index],'IDLgrSymbol') or $
                         OBJ_ISA(Item_Object[index],'IDLgrPattern'))) $
                  then begin
                    MESSAGE,$
                      'Unable to convert variable to type object reference.',$
                      /info
                    convertError = 1
                endif
            endif $
            else begin
                if (Item_Object[index] ne OBJ_NEW()) then begin
                    MESSAGE,$
                      'Unable to convert variable to type object reference.',$
                      /info
                    convertError = 1
                endif
            endelse
        endfor
        if (not convertError) then begin
            *self.pItem_Object = Item_Object
            self.bRecompute = 1
        endif
    endif
    if (N_ELEMENTS(Item_Thick) gt 0) then begin
        *self.pItem_Thick = Item_Thick
        self.bRecompute = 1
    endif

    convertError = 0
    if (N_ELEMENTS(Item_Type) gt 0) then begin
        for index = 0,N_ELEMENTS(Item_Type)-1 do begin
            if (not FINITE(Item_Type[index])) then begin
                MESSAGE,'Infinite or invalid (NaN) operands not allowed.',/info
                convertError = 1
            endif $
            else $
              if ((Item_Type[index] lt 0) or (Item_Type[index] gt 1)) $
              then begin
                MESSAGE,'Out of range error: ITEM_TYPE',/info
                convertError = 1
            endif
        endfor
        if (not convertError) then begin
            *self.pItem_Type = Item_Type
            self.bRecompute = 1
        endif
    endif

    if (N_ELEMENTS(Outline_Color) gt 0) then $
      self.oOutline->SetProperty, COLOR = Outline_Color
    if (N_ELEMENTS(Outline_Thick) gt 0) then begin
        if (FINITE(Outline_Thick)) then $
          self.oOutline->SetProperty, THICK = Outline_Thick
    endif
    if (N_ELEMENTS(Text_Color) gt 0) then begin
        *self.pText_Color = Text_Color
        self.bRecompute = 1
    endif

    ;coordinate conversion
    self.oScaleNode->GetProperty, TRANSFORM = transform
    if(N_ELEMENTS(Xcoord_Conv) gt 1) then begin
        fin_check = WHERE(FINITE(Xcoord_conv) eq 0)
        if (fin_check[0] eq -1) then begin
            Xcoord_conv = FLOAT(Xcoord_conv)
            if (Xcoord_Conv[1] eq 0.0) then begin
                Xcoord_Conv[1] = 1.0
                MESSAGE,'Scale factor of 0.0 not allowed, using 1.0',/info
            endif
            if (transform[0,0] ne Xcoord_Conv[1]) then begin
                transform[0,0] = Xcoord_Conv[1]
                self.bRecompute = 1
            endif
            transform[3,0] = Xcoord_Conv[0]
        endif $
        else $
          MESSAGE,'Infinite or invalid (NaN) operands not allowed.',/info
    endif
    if(N_ELEMENTS(Ycoord_Conv) gt 1) then begin
        fin_check = WHERE(FINITE(Ycoord_conv) eq 0)
        if (fin_check[0] eq -1) then begin
            Ycoord_conv = FLOAT(Ycoord_conv)
            if (Ycoord_Conv[1] eq 0.0) then begin
                Ycoord_Conv[1] = 1.0
                MESSAGE,'Scale factor of 0.0 not allowed, using 1.0',/info
            endif
            if (transform[1,1] ne Ycoord_Conv[1]) then begin
                transform[1,1] = Ycoord_Conv[1]
                self.bRecompute = 1
            endif
            transform[3,1] = Ycoord_Conv[0]
        endif $
        else $
          MESSAGE,'Infinite or invalid (NaN) operands not allowed.',/info
    endif
    if(N_ELEMENTS(Zcoord_Conv) gt 1) then begin
        fin_check = WHERE(FINITE(Zcoord_conv) eq 0)
        if (fin_check[0] eq -1) then begin
            Zcoord_conv = FLOAT(Zcoord_conv)
            if (Zcoord_Conv[1] eq 0.0) then begin
                Zcoord_Conv[1] = 1.0
                MESSAGE,'Scale factor of 0.0 not allowed, using 1.0',/info
            endif
            if (transform[2,2] ne Zcoord_Conv[1]) then begin
                transform[2,2] = Zcoord_Conv[1]
                self.bRecompute = 1
            endif
            transform[3,2] = Zcoord_Conv[0]
        endif $
        else $
          MESSAGE,'Infinite or invalid (NaN) operands not allowed.',/info
    endif
    self.oScaleNode->SetProperty, TRANSFORM = transform

    if (N_ELEMENTS(recompute) gt 0) then begin
        if (recompute gt 0) then $
          self.bRecompute = 1 $
        else $
          self.bRecompute = 0
    endif

    if (self.bRecompute) then begin
        self->DefaultArrays
        self->CreateGlyphs
    endif
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrLegend::GetProperty
;
; PURPOSE:
;       The IDLgrLegend::GetProperty procedure method retrieves the
;       value of a property or group of properties for the legend.
;
; CALLING SEQUENCE:
;       oLegend->[IDLgrLegend::]GetProperty
;
; INPUTS:
;       There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;       Any keyword to IDLgrLegend::Init or IDLgrModel::init followed by the
;       word "Get" can be retrieved using IDLgrLegend::GetProperty.  In
;       addition the following keywords are available:
;
;       ALL:    Set this keyword to a named variable that will contain
;               an anonymous structure containing the values of all the
;               retrievable properties associated with this object.
;               NOTE: UVALUE is not returned in this struct.
;       XRANGE: Set this keyword to a named variable that will contain
;               a two-element vector of the form [xmin,xmax] specifying
;               the range of the x data coordinates covered by the Legend.
;       YRANGE: Set this keyword to a named variable that will contain
;               a two-element vector of the form [ymin,ymax] specifying
;               the range of the y data coordinates covered by the Legend.
;       ZRANGE: Set this keyword to a named variable that will contain
;               a two-element vector of the form [zmin,zmax] specifying
;               the range of the z data coordinates covered by the Legend.
;
; EXAMPLE:
;       oLegend->GetProperty, PARENT = parent
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/26/97
;-

PRO IDLgrLegend::GetProperty,  ALL = All, BORDER_GAP = Border_Gap, $
               COLUMNS = Columns, FILL_COLOR = Fill_Color, $
               FONT = Font, GAP = Gap, $
               GLYPH_WIDTH = glyphWidth, $
               ITEM_COLOR = Item_Color, $
               ITEM_LINESTYLE = Item_Linestyle, ITEM_NAME = Item_Name, $
               ITEM_OBJECT = Item_Object, ITEM_THICK = Item_Thick, $
               ITEM_TYPE = Item_Type, $
               OUTLINE_COLOR = Outline_Color, $
               OUTLINE_THICK = Outline_Thick, $
               SHOW_OUTLINE = Show_Outline, $
               SHOW_FILL = Show_Fill, TEXT_COLOR = Text_Color, $
               TITLE = Title, $
               XCOORD_CONV = Xcoord_Conv, YCOORD_CONV = Ycoord_Conv, $
               ZCOORD_CONV = Zcoord_Conv, XRANGE = Xrange, $
               YRANGE = Yrange, ZRANGE = Zrange, _REF_EXTRA=e

  compile_opt idl2, hidden
  ON_ERROR, 2

    Border_Gap = self.Border_Gap
    Columns = self.Columns
    self.oFill->GetProperty, COLOR = Fill_Color, HIDE = Show_Fill
    Show_Fill = 1 - Show_Fill
    Font = self.oFont
    Gap = self.Gap
    glyphWidth = self.glyphWidth
    Item_Color = (*self.pItem_Color)
    Item_Linestyle = (*self.pItem_Linestyle)
    Item_Name = (*self.pItem_Name)
    Item_Object = (*self.pItem_Object)
    Item_Thick = (*self.pItem_Thick)
    Item_Type = (*self.pItem_Type)
    self.oOutline->GetProperty, COLOR = Outline_Color, THICK = Outline_Thick, $
      HIDE = Show_Outline
    Show_Outline = 1 - Show_Outline
    Text_Color = (*self.pText_Color)
    Title = self.oTitle

    ;; Get the transform matrix
    self.oScaleNode->GetProperty, TRANSFORM = transform
    Xcoord_Conv = [transform[3,0],transform[0,0]]
    Ycoord_Conv = [transform[3,1],transform[1,1]]
    Zcoord_Conv = [transform[3,2],transform[2,2]]

    self.oOutline->GetProperty, XRANGE = Xrange
    self.oOutline->GetProperty, YRANGE = Yrange
    self.oOutline->GetProperty, ZRANGE = Zrange

    self->IDLgrModel::GetProperty, _EXTRA=e

    if ARG_PRESENT(All) then begin
        self->IDLgrModel::GetProperty, ALL=ModelProperties

        All = CREATE_STRUCT( $
            ModelProperties, $
            'Border_Gap', Border_Gap, $
            'Columns', Columns, $
            'Fill_Color', Fill_Color, $
            'Font', Font, $
            'Gap', Gap, $
            'Glyph_Width', glyphWidth, $
            'Item_Color', Item_Color, $
            'Item_Linestyle', Item_Linestyle, $
            'Item_Name', Item_Name, $
            'Item_Object', Item_Object, $
            'Item_Thick', Item_Thick, $
            'Item_Type', Item_Type, $
            'Outline_Color', Outline_Color, $
            'Outline_Thick', Outline_Thick, $
            'Show_Outline', Show_Outline, $
            'Show_Fill', Show_Fill, $
            'Text_Color', Text_Color, $
            'Title', Title, $
            'xRange', xRange, $
            'yRange', yRange, $
            'zRange', zRange, $
            'Xcoord_Conv', Xcoord_Conv, $
            'Ycoord_Conv', Ycoord_Conv, $
            'Zcoord_Conv', Zcoord_Conv $
          )
    endif

END

;+
;----------------------------------------------------------------------------
; IDLgrLegend__Define
;
; Purpose:
;  Defines the object structure for an IDLgrLegend object.
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/26/97
;-

PRO IDLgrLegend__Define

    COMPILE_OPT hidden

    struct = { IDLgrLegend, $
               INHERITS IDLgrModel, $
               oScaleNode: OBJ_NEW(), $
               Border_Gap: 0.1, $
               Columns: 1, $
               oOutline: OBJ_NEW(), $
               oFill: OBJ_NEW(), $
               oFont: OBJ_NEW(), $
               Gap: 0.1, $
               glyphWidth: 0.8, $
               pItem_Color: PTR_NEW(), $
               pItem_Linestyle: PTR_NEW(), $
               pItem_Name: PTR_NEW(), $
               pItem_Object: PTR_NEW(), $
               pItem_Thick: PTR_NEW(), $
               pItem_Type: PTR_NEW(), $
               oTitle: OBJ_NEW(), $
               pText_Color: PTR_NEW(), $
               bRecompute: 1, $
               pGlyphs: PTR_NEW(), $
               pTexts: PTR_NEW(), $
               hGlyphWidth: 0.0, $
               vGlyphWidth: 0.0, $
               colorMode: 0, $
               cleanLeave: PTR_NEW(), $
               cleanGlyphs: PTR_NEW(), $
               IDLgrLegendVersion: 3 $
             }
END

