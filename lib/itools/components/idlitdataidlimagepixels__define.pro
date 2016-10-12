; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitdataidlimagepixels__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitDataIDLImagePixels
;
; PURPOSE:
;   This file implements the IDLitDataIDLImagePixels class.
;   This class is used to store pixel data.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitDataContainer
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitDataIDLImagePixels::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitDataIDLImagePixels::Init
;
; Purpose:
; The constructor of the IDLitDataIDLImagePixels object.
;
; Parameters:
;   Image    - (optional) The image data to store in the object
;
; Properties:
;   See properties from superclass
;
function IDLitDataIDLImagePixels::Init, Image, _REF_EXTRA=_extra

    compile_opt idl2, hidden

@idlit_on_error2

    ; Init superclass
    if (self->IDLitDataContainer::Init( ICON='rgba', $
        TYPE='IDLIMAGEPIXELS', _EXTRA=_extra) eq 0) then $
        return, 0

    ; Register properties

    ; Note - For now, the interleave setting is de-sensitized
    ; since it is unusual to want to change the interleaving after
    ; the initial display.
    self->RegisterProperty, 'INTERLEAVE', $
        NAME='Interleaving', $
        SENSITIVE=0, $
        ENUMLIST=['Pixel','Scanline','Planar'], $
        DESCRIPTION='Interleave setting for image data'

    ; If data was provided, determine how to use it.

    if(n_elements(Image) gt 0)then begin
        iStatus =  self->IDLitDataIDLImagePixels::SetData(Image, $
                                                          _EXTRA=_extra)
        if(iStatus eq 0)then begin
            self->IDLitDataContainer::Cleanup
            return, 0
        endif
    endif
    return, 1
end

;---------------------------------------------------------------------------
; IDLitDataIDLImagePixels::Cleanup
;
; Purpose:
; The destructor for the class.
;
; Parameters:
; None.
;
;pro IDLitDataIDLImagePixels::Cleanup
;
;    compile_opt idl2, hidden
;
;    ; Cleanup superclass
;    self->IDLitDataContainer::Cleanup
;end

;---------------------------------------------------------------------------
; IDLitDataIDLImagePixels::SetData
;
; Purpose:
;   Override SetData for the DataContainer.  This function unpacks the image
;   into individual planes or channels.
;
; Parameters:
;   Data:  A 2- or 3-dimensional array representing the image data.
;
; Keyword Parameters:
;   CHANNEL:   Set this keyword to the index of the channel (or plane)
;     that the given Data represents.  This keyword only applies if the
;     Data parameter is 2-dimensional.
;
;   INTERLEAVE:    Set this keyword to an integer indicating how the
;     image is interleaved.  Valid values include:
;       0: Pixel interleaved - RGB data has dimensions:  (3,M,N)
;                              RGBA data:                (4,M,N)
;                              Luminance-Alpha data:     (2,M,N)
;       1: Row interleaved   - RGB data has dimensions:  (M,3,N)
;                              RGBA data:                (M,4,N)
;                              Luminance-Alpha data:     (M,2,N)
;       2: Plane interleaved - RGB data has dimensions:  (M,N,3)
;                              RGBA data:                (M,N,4)
;                              Luminance-Alpha data:     (M,N,2)
;
;   ORDER: Set this keyword to a non-zero value to indicate that the provided
;     image data should be flipped vertically before storing within the
;     data object.
;
function IDLitDataIDLImagePixels::SetData, Data, IdentPath, $
    CHANNEL=inChannel, $
    INTERLEAVE=interleave, $
    NO_COPY=NO_COPY, $
    ORDER=order, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    nDims = SIZE(Data, /N_DIMENSIONS)
    dims = SIZE(Data, /DIMENSIONS)

    if ((nDims lt 2) or (nDims gt 3)) then $
        return, 0

    if (nDims eq 2) then begin
        ; Single channel image.
        channel = (N_ELEMENTS(inChannel) ne 0) ? inChannel[0] : 0
        if(channel lt 0 || channel gt 3)then begin
            Message, IDLitLangCatQuery('Message:Component:InvalidChannel'), /CONTINUE
            return,0
        endif
        nChannels = channel+1
    endif else begin
        ; Multi-channel image.
        if (N_ELEMENTS(interleave) ne 0) then $
            self._interleave = interleave $
        else begin
            ; Attempt to auto-determine interleaving.
            i = WHERE(dims eq 3, count)     ; Try RGB first.
            if (count eq 0) then $
                i = WHERE(dims eq 4, count) ; ...then RGBA.
            if (count eq 0) then $
                i = WHERE(dims eq 2, count) ; ...then Luminance-Alpha.

            if (count gt 0) then $
                self._interleave = i[0] $
            else begin
                ; Use minimum dimensions
                minDim = MIN(dims, imin)
                self._interleave = imin
            endelse
        endelse
        if(self._interleave lt 0 || self._interleave gt 2)then begin
            Message, IDLitLangCatQuery('Message:Component:InvalidInterleave'), /CONTINUE
            return,0
        endif
        nChannels = dims[self._interleave]

        ; Verify that the interleave dimension is either 2, 3, or 4.
        if (nChannels lt 2) then begin
            Message, IDLitLangCatQuery('Message:Component:InvalidImageDim'), /CONTINUE
            return,0
        endif

    endelse

    ; disable any notification propagation
    self->DisableNotify

    ; Check if any image planes are currently contained.
    ; If so, determine whether they can be recycled.
    oPlanes = self->IDL_Container::Get(/all, count=nCount)

    if (nChannels gt nCount) then begin
        if (nChannels le 2) then begin
            names = [IDLitLangCatQuery('UI:Channel:Gray'), $
                IDLitLangCatQuery('UI:Channel:Alpha')]
        endif else if (nChannels le 4) then begin
            names = [IDLitLangCatQuery('UI:Channel:Red'), $
                IDLitLangCatQuery('UI:Channel:Green'), $
                IDLitLangCatQuery('UI:Channel:Blue'), $
                IDLitLangCatQuery('UI:Channel:Alpha')]
        endif else begin
            names = IDLitLangCatQuery('UI:Channel') + ' ' + Sindgen(nChannels)
        endelse
        for i=nCount, nChannels-1 do begin
           oNew = OBJ_NEW('IDLitDataIDLArray2D', NAME=names[i])
           self->Add, oNew
           oPlanes = (i eq 0 ? oNew : [oPlanes, oNew])
       endfor

    endif else begin ; We may need to prune.
        if (nChannels lt nCount) then begin
           oSave = oPlanes[0:nChannels-1]
           oRM = oPlanes[nChannels:*]
           self->Remove, oRM
           OBJ_DESTROY, oRM
           oPlanes = oSave
        endif
    endelse

    ; Now set the image plane data.
    if (nDims eq 2) then begin
        if (KEYWORD_SET(order)) then begin
            result = oPlanes[channel]->SetData( $
                KEYWORD_SET(NO_COPY) ? $
                    ROTATE(TEMPORARY(Data),7) : $
                    ROTATE(Data, 7), $
                NO_COPY=NO_COPY)
        endif else begin
            result = oPlanes[channel]->SetData(Data, $
                NO_COPY=NO_COPY)
        endelse
    endif else begin

        result = 1

        ; If pixel interleaved, it is too slow to extract the separate
        ; planes by simply indexing. So instead, take the transpose of
        ; the data (after collapsing the col/row dimensions),
        ; and extract using planes. This uses extra memory, but
        ; is about twice as fast.
        if (self._interleave eq 0) then begin
            ; Collapse col/row dims because a 2D transpose is faster than 3D.
            Data = REFORM(Data, nChannels, dims[1]*dims[2], /OVERWRITE)

            if (KEYWORD_SET(no_copy)) then begin
                ; Transpose and remove old data.
                DataTrans = TRANSPOSE(TEMPORARY(Data))
            endif else begin
                ; Transpose (makes a new copy).
                DataTrans = TRANSPOSE(Data)
                ; Put Data back to original shape.
                Data = REFORM(Data, nChannels, dims[1], dims[2], /OVERWRITE)
            endelse

            ; Put our new DataTrans into its correct shape.
            DataTrans = REFORM(DataTrans, dims[1], dims[2], nChannels, /OVERWRITE)
        endif

        for i=0, nChannels-1 do begin

            case self._interleave of

                0: if (i eq nChannels-1) then begin
                    ; Free up our now unnecessary DataTrans, to save memory.
                    DataTrans = DataTrans[*, *, i]
                    d = TEMPORARY(DataTrans)
                   endif else begin
                    d = DataTrans[*, *, i]
                   endelse

                1: d = REFORM(Data[*,i,*])

                2: if ((i eq nChannels-1) && KEYWORD_SET(no_copy)) then begin
                    ; Free up our now unnecessary Data, to save memory.
                    Data = Data[*, *, i]
                    d = TEMPORARY(Data)
                endif else begin
                    d = Data[*, *, i]
                endelse
                else: begin
                    Message, IDLitLangCatQuery('Message:Component:InvalidInterleave'), /CONTINUE
                    return,0
                end
            endcase

            if (~oPlanes[i]->SetData( $
                KEYWORD_SET(order) ? ROTATE(TEMPORARY(d), 7) : d, /NO_COPY)) then $
                result = 0
        endfor

    endelse
    ; enable any notification propagation. This will send any pending
    ; updates
    self->EnableNotify

    return, result
end


;---------------------------------------------------------------------------
; IDLitDataIDLImagePixels::GetData
;
; Purpose:
; Override GetData for the DataContainer.  This function repacks the image
; from individual planes or channels into a packed format.
;
; Parameters:
; None.
;
;  Keywords:
;   INTERLEAVE: Set this keyword to override the stored
;       interleave and return the data in the specified format.
;
function IDLitDataIDLImagePixels::GetData, Data, IdentPath, $
    INTERLEAVE=interleaveIn, $
    NAN=nan, $
    POINTER=pointer, $
    _REF_EXTRA=_extra


    compile_opt idl2, hidden

    ; Got ID, pass control up
    if (keyword_set(IdentPath)) then begin
        return, self->IDLitDataContainer::GetData(Data, IdentPath, $
            NAN=nan, $
            POINTER=pointer, $
            _EXTRA=_extra)
    endif

    oPlanes = self->Get(/ALL, COUNT=nPlanes)
    if(nPlanes eq 0)then return, 0

    ; Get data from first plane
    result = oPlanes[0]->GetData(Data, NAN=nan, POINTER=pointer, _EXTRA=_extra)

    if (nPlanes eq 1) then $
        return, result

    ; Assemble planes.
    for i=1, nPlanes-1 do begin
        ; If any of the planes have NaN, then return NaN=true.
        result = oPlanes[i]->GetData(d, NAN=nan1, POINTER=pointer, $
            _EXTRA=_extra)
        nan = nan || nan1
        Data = [[[TEMPORARY(Data)]], [[d]]] ; concat along 3rd dim
    endfor
    dims = SIZE(Data, /DIMENSIONS)

    ; If pointers are being retrieved, simply remove any leading
    ; 1's from the dimensions, and return.
    if (KEYWORD_SET(pointer)) then begin
        Data = REFORM(Data)
        return, result
    endif

    ; Convert back to original interleave.
    case self._interleave of
            ; Faster to collapse dims and then do a 2D transpose.
        0:  Data = REFORM(TRANSPOSE(REFORM(Data, dims[0]*dims[1], dims[2], $
            /OVERWRITE)), dims[2], dims[0], dims[1])
        1:  Data = TRANSPOSE(temporary(Data), [0,2,1])
        2:  ; no transpose needed
    endcase

    return, result
end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitDataIDLImagePixels::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;

pro IDLitDataIDLImagePixels::GetProperty, $
    CMYK=cmyk, $
    INTERLEAVE=interleave, $
    RESOLUTION=resolution, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (ARG_PRESENT(cmyk)) then cmyk = self._bIsCMYK

    if (ARG_PRESENT(resolution)) then $
        resolution = self._resolution

    if(arg_present(interleave))then $
        interleave =  self._interleave

    if(n_elements(_super) gt 0)then $
        self->IDLitDataContainer::GetProperty, _EXTRA=_super

end

;---------------------------------------------------------------------------
; IDLitDataIDLImagePixels::SetProperty
;
; Purpose:
;   Used to set the value of the properties associated with this class.
;

pro IDLitDataIDLImagePixels::SetProperty, $
    CMYK=cmyk, $
    INTERLEAVE=interleave, $
    RESOLUTION=resolution, $
    _EXTRA=_super

    compile_opt idl2, hidden

    if (N_ELEMENTS(cmyk)) then self._bIsCMYK = KEYWORD_SET(cmyk)

    if (N_ELEMENTS(resolution) eq 1) then $
        self._resolution = resolution

    if(n_elements(interleave) ne 0) then begin
        interleave = BYTE(interleave)
        switch interleave of
            0:
            1:
            2:  begin
                if (interleave ne self._interleave) then begin
           ; Retrieve original data.
                    haveData = self->GetData(data)

                    oldInterleave = self._interleave
                    self._interleave = interleave

                    ; Recompute the image planes.
                    if (haveData ne 0) then begin
                        success = self->SetData(data, INTERLEAVE=interleave)
                        if (~success) then $
                            void = self->SetData(data, $
                                INTERLEAVE=oldInterleave)
                    endif
                endif
                break
                end
            else: Message, IDLitLangCatQuery('Message:Component:InvalidInterleave'), /CONTINUE
        endswitch
    endif

    if(n_elements(_super) gt 0)then $
        self->IDLitDataContainer::SetProperty, _EXTRA=_super
end

;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitDataIDLImagePixels__Define
;
; Purpose:
; Class definition for the IDLitDataIDLImagePixels class
;

pro IDLitDataIDLImagePixels__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitDataIDLImagePixels, $
          inherits   IDLitDataContainer,$
          _interleave   : 0B,            $
          _bIsCMYK: 0b,                  $ ; Pixels are CMYK, not RGB
          _resolution : 0d               $ ; image resolution in DPI
         }
end
