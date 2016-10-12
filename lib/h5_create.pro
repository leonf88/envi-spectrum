; $Id: //depot/idl/releases/IDL_80/idldir/lib/h5_create.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   H5_CREATE
;
; PURPOSE:
;   Creates an HDF5 file based on a nested structure containing all of
;   the groups, datasets, and attributes.
;
; CALLING SEQUENCE:
;
;   H5_CREATE, File, Data
;
; INPUTS:
;
;   FILE: A scalar string giving the file to parse.
;
;   DATA: A (nested) structure
;
;
; KEYWORD PARAMETERS:
;
;   NONE
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, August 2004
;   Modified by:
;
;-

;;----------------------------------------------------------------------------
;; IDLffH5Create::H5_CREATE_GROUP
;;
;; Purpose:
;;   Creates a group
;;
;; Parameters:
;;   ID - HDF5 identifier in which item will be created
;;
;; Keywords:
;;   NONE
;;
FUNCTION IDLffH5Create::h5_create_group, id
  compile_opt idl2, hidden

  catch, err
  IF (err NE 0) THEN BEGIN
    catch,/cancel
    MESSAGE, /RESET
    self.msg = 'Unable to create group: '+self.name
    return, 0
  ENDIF

  ;; check for hardlink tag
  wh = where(tag_names(*self.data) EQ '_HARDLINK')
  IF (wh NE -1) && ((*self.data).(wh) NE '') THEN BEGIN
    ;; cache hard link for later creation in case the object to be
    ;; linked to does not yet exist
    struct = {_H5CREATELINKS, id, (*self.data).(wh), self.name}
    IF ~ptr_valid(self.hardlinks) THEN $
      self.hardlinks = ptr_new(struct) $
    ELSE $
      *self.hardlinks = [*self.hardlinks, struct]
    return, 1
  ENDIF

  ;; create a group only if this is not the top level group
  IF (self.name EQ '/') THEN BEGIN
    group_id = id
  ENDIF ELSE BEGIN
    group_id = H5G_CREATE(id, self.name)
    closeFlag = 1b
    ;; comments cannot go on the top level group
    wh = where(tag_names(*self.data) EQ '_COMMENT')
    IF (wh NE -1) THEN BEGIN
      comment = (*self.data).(wh)
      H5G_SET_COMMENT, id, self.name, comment
    ENDIF
  ENDELSE

  ;; process any additional structures
  FOR i=0,n_tags(*self.data)-1 DO BEGIN
    ;; find all structures not named _DATA
    IF ((size((*self.data).(i),/type) EQ 8) && $
        ((tag_names(*self.data))[i] NE '_DATA')) THEN BEGIN
      ;; pass a pointer instead of the data structure
      ;; save current pointer
      ptr = ptr_new(*self.data)
      ;; update data pointer
      *self.data = (*self.data).(i)
      self.name = (tag_names(*ptr))[i]
      wh = where(tag_names(*self.data) EQ '_NAME')
      IF (wh NE -1) THEN self.name = (*self.data).(wh)
      type = strupcase((*self.data)._type)

      ;; call appropriate creation routine
      CASE type OF
        'DATASET' : success = self->h5_create_dataset(group_id)
        'DATATYPE' : success = self->h5_create_datatype(group_id)
        'GROUP' : success = self->h5_create_group(group_id)
        'ATTRIBUTE' : success = self->h5_create_attribute(group_id)
        'LINK' : success = self->h5_create_link(group_id)
        ELSE :
      ENDCASE
      ;; restore current pointer
      *self.data = *ptr
      ptr_free, ptr
      IF ~success THEN return, 0
    ENDIF
  ENDFOR

  return, 1

END

;;----------------------------------------------------------------------------
;; IDLffH5Create::H5_CREATE_LINK
;;
;; Purpose:
;;   Creates a link
;;
;; Parameters:
;;   ID - HDF5 identifier in which item will be created
;;
;; Keywords:
;;   NONE
;;
FUNCTION IDLffH5Create::h5_create_link, id
  compile_opt idl2, hidden

  wh = where(tag_names(*self.data) EQ '_NAME')
  IF (wh NE -1) THEN self.name = (*self.data).(wh)

  catch, err
  IF (err NE 0) THEN BEGIN
    catch,/cancel
    MESSAGE, /RESET
    self.msg = 'Unable to create link: '+self.name
    return, 0
  ENDIF

  ;; get name of object to which the link will point
  currentname = string((*self.data)._data)
  ;; if names do not exist then do not create a link
  IF (currentname EQ '') || (self.name EQ '') THEN BEGIN
    self.msg = 'Unable to create link with no name'
    return, 0
  ENDIF

  ;; assume soft link
  linktype = 1b

  wh = where(tag_names(*self.data) EQ '_LINKTYPE')
  IF (wh NE -1) THEN linktype = strupcase((*self.data).(wh)) EQ 'SOFT'

  IF ~linktype THEN BEGIN
    ;; cache hard link for later creation in case the object to be
    ;; linked to does not yet exist
    struct = {_H5CREATELINKS, id, currentname, self.name}
    IF ~ptr_valid(self.hardlinks) THEN $
      self.hardlinks = ptr_new(struct) $
    ELSE $
      *self.hardlinks = [*self.hardlinks, struct]
    return, 1
  ENDIF

  ;; create link
  H5G_LINK, self.fid, currentname, self.name, softlink=linktype, NEW_LOC_ID=id

  return, 1

END

;;----------------------------------------------------------------------------
;; IDLffH5Create::H5_CREATE_ATTRIBUTE
;;
;; Purpose:
;;   Creates an attribute
;;
;; Parameters:
;;   ID - HDF5 identifier in which item will be created
;;
;; Keywords:
;;   NONE
;;
FUNCTION IDLffH5Create::h5_create_attribute, id
  compile_opt idl2, hidden

  wh = where(tag_names(*self.data) EQ '_NAME')
  IF (wh NE -1) THEN self.name = (*self.data).(wh)

  catch, err
  IF (err NE 0) THEN BEGIN
    catch,/cancel
    MESSAGE, /RESET
    self.msg = 'Unable to create attribute: '+self.name
    return, 0
  ENDIF

  ;; create a datatype
  datatype_id = self->H5_CREATE_IDL_CREATE((*self.data)._data)
  ;; create a dataspace
  IF (n_elements((*self.data)._data) EQ 1) && $
    ~size((*self.data)._data,/n_dimensions) THEN BEGIN
    dataspace_id = H5S_CREATE_SCALAR()
  ENDIF ELSE BEGIN
    dataspace_id = H5S_CREATE_SIMPLE(size((*self.data)._data,/dimensions)>1)
  ENDELSE
  ;; create the attribute
  attr_id = H5A_CREATE(id,self.name,datatype_id,dataspace_id)
  ;; write the data to the attribute
  H5A_WRITE,attr_id,(*self.data)._data
  ;; close the identifiers
  H5A_CLOSE,attr_id
  H5S_CLOSE,dataspace_id
  H5T_CLOSE,datatype_id

  return, 1

END

;;----------------------------------------------------------------------------
;; IDLffH5Create::H5_CREATE_DATATYPE_GET_DATA
;;
;; Purpose:
;;   Returns a data item based on the tags in the structure
;;
;; Parameters:
;;   PDATA - Pointer to a structure
;;
;; Keywords:
;;   MEMBER_NAMES - output variable, returns a list of names if the
;;                  returned data is a structure
;;
FUNCTION IDLffH5Create::h5_create_datatype_get_data, pdata, $
                                                     MEMBER_NAMES=member_names
  compile_opt idl2, hidden

  CASE (*pdata)._datatype OF
    'H5T_INTEGER' : BEGIN
      CASE (*pdata)._storagesize OF
        1 : return, 1b
        2 : return, strupcase((*pdata)._sign) EQ 'SIGNED' ? 1s : 1us
        4 : return, strupcase((*pdata)._sign) EQ 'SIGNED' ? 1l : 1ul
        8 : return, strupcase((*pdata)._sign) EQ 'SIGNED' ? 1ll : 1ull
      ENDCASE
    END
    'H5T_FLOAT' : BEGIN
      return, (*pdata)._storagesize EQ 4 ? 1.0 : 1.0d
    END
    'H5T_STRING' : BEGIN
      return, strjoin(replicate('a',(*pdata)._storagesize-1))
    END
    'H5T_COMPOUND' : BEGIN
      ;; no data provided, look for additional structures
      FOR i=0,n_tags(*pdata)-1 DO BEGIN
        ;; find all structures not named _DATA
        IF ((size((*pdata).(i),/type) EQ 8) && $
            ((tag_names(*pdata))[i] NE '_DATA')) THEN BEGIN
          ptr = ptr_new((*pdata).(i))
          IF (strupcase((*ptr)._type) EQ 'DATATYPE') THEN BEGIN
            wh = where(tag_names(*ptr) EQ '_NAME')
            IF (wh NE -1) THEN $
              name = (*ptr)._name $
            ELSE $
              name = (tag_names(*pdata))[i]
            IF (n_elements(struct) EQ 0) THEN BEGIN
              struct = $
                create_struct(name, self->h5_create_datatype_get_data(ptr))
              member_names = name
            ENDIF ELSE BEGIN
              struct = $
                create_struct(struct, name, $
                              self->h5_create_datatype_get_data(ptr))
              member_names = [member_names, name]
            ENDELSE
          ENDIF
          ptr_free, ptr
        ENDIF
      ENDFOR
      return, struct
    END
    ELSE :
  ENDCASE

  return, -1

END

;;----------------------------------------------------------------------------
;; IDLffH5Create::H5_CREATE_DATATYPE
;;
;; Purpose:
;;   Creates a datatype
;;
;; Parameters:
;;   ID - HDF5 identifier in which item will be created
;;
;; Keywords:
;;   NONE
;;
FUNCTION IDLffH5Create::h5_create_datatype, id
  compile_opt idl2, hidden

  wh = where(tag_names(*self.data) EQ '_NAME')
  IF (wh NE -1) THEN self.name = (*self.data).(wh)

  catch, err
  IF (err NE 0) THEN BEGIN
    catch,/cancel
    MESSAGE, /RESET
    self.msg = 'Unable to create datatype: '+self.name
    return, 0
  ENDIF

  ;; check for hardlink tag
  wh = where(tag_names(*self.data) EQ '_HARDLINK')
  IF (wh NE -1) && ((*self.data).(wh) NE '') THEN BEGIN
    ;; cache hard link for later creation in case the object to be
    ;; linked to does not yet exist
    struct = {_H5CREATELINKS, id, (*self.data).(wh), self.name}
    IF ~ptr_valid(self.hardlinks) THEN $
      self.hardlinks = ptr_new(struct) $
    ELSE $
      *self.hardlinks = [*self.hardlinks, struct]
    return, 1
  ENDIF

  wh = where(tag_names(*self.data) EQ '_DATA')
  ;; datatype information is either in the _DATA tag or can be derived
  ;; from the _DATATYPE and _STORAGESIZE fields
  IF (wh NE -1) THEN BEGIN
    data = (*self.data)._data
  ENDIF ELSE BEGIN
    ;; need _DATATYPE, _STORAGESIZE, and _SIGN to be able to
    ;; reconstruct the datatype
    wh1 = where(tag_names(*self.data) EQ '_DATATYPE')
    wh2 = where(tag_names(*self.data) EQ '_STORAGESIZE')
    wh3 = where(tag_names(*self.data) EQ '_SIGN')
    IF (wh1 EQ -1) || (wh2 EQ -1) || (wh3 EQ -1) THEN BEGIN
      self.msg = 'Unable to create datatype: '+self.name+ $
                 ', not enough data provided'
      return, 0
    ENDIF

    data = self->h5_create_datatype_get_data(self.data, member_names=mnames)
    ;; if a -1 was returned then cancel operation
    IF (size(data,/type) NE 7) && (size(data,/type) NE 8) $
      && (n_elements(data) EQ 1) && (data EQ -1) THEN BEGIN
      self.msg = 'Unable to create datatype: '+self.name
      return, 0
    ENDIF
  ENDELSE

  datatype_id = self->H5_CREATE_IDL_CREATE(data,mnames)
  H5T_COMMIT, id, self.name, datatype_id

  ;; add any attributes
  FOR i=0,n_tags(*self.data)-1 DO BEGIN
    ;; find all structures not named _DATA
    IF ((size((*self.data).(i),/type) EQ 8) && $
        ((tag_names(*self.data))[i] NE '_DATA')) THEN BEGIN

      IF (strupcase(((*self.data).(i))._type) EQ 'ATTRIBUTE') THEN BEGIN
        ;; pass a pointer instead of the data structure
        ;; save current pointer
        ptr = ptr_new(*self.data)
        ;; update data pointer
        *self.data = (*self.data).(i)

        self.name = (tag_names(*ptr))[i]
        wh = where(tag_names(*self.data) EQ '_NAME')
        IF (wh NE -1) THEN self.name = (*self.data).(wh)
        IF ~self->h5_create_attribute(datatype_id) $
          THEN return,0
        ;; restore current pointer
        *self.data = *ptr
        ptr_free, ptr
      ENDIF
    ENDIF
  ENDFOR

  H5T_CLOSE, datatype_id

  return, 1

END

;;----------------------------------------------------------------------------
;; IDLffH5Create::H5_CREATE_DATASET
;;
;; Purpose:
;;   Creates a dataset
;;
;; Parameters:
;;   ID - HDF5 identifier in which item will be created
;;
;; Keywords:
;;   NONE
;;
FUNCTION IDLffH5Create::h5_create_dataset, id
  compile_opt idl2, hidden

  wh = where(tag_names(*self.data) EQ '_NAME')
  IF (wh NE -1) THEN self.name = (*self.data).(wh)

  catch, err
  IF (err NE 0) THEN BEGIN
    catch,/cancel
    MESSAGE, /RESET
    self.msg = 'Unable to create dataset: '+self.name
    return, 0
  ENDIF

  ;; check for hardlink tag
  wh = where(tag_names(*self.data) EQ '_HARDLINK')
  IF (wh NE -1) && ((*self.data).(wh) NE '') THEN BEGIN
    ;; cache hard link for later creation in case the object to be
    ;; linked to does not yet exist
    struct = {_H5CREATELINKS, id, (*self.data).(wh), self.name}
    IF ~ptr_valid(self.hardlinks) THEN $
      self.hardlinks = ptr_new(struct) $
    ELSE $
      *self.hardlinks = [*self.hardlinks, struct]
    return, 1
  ENDIF

  ;; create a datatype
  datatype_id = self->H5_CREATE_IDL_CREATE(((*self.data)._data)[0])

  ;; create a dataspace
  ;; check for dimensions tag, if present use it, otherwise get the
  ;; dimensions from the data itself.
  ;; Note: getting the dimensions from the data drops trailing
  ;; degenerate arrays. 
  wh = where(tag_names(*self.data) EQ '_DIMENSIONS', cnt)
  if (cnt ne 0) then begin
    dims = (*self.data).(wh)
    if (total(dims) eq 0) then begin
      dataspace_id = H5S_CREATE_SCALAR()
    endif else begin
      dataspace_id = H5S_CREATE_SIMPLE(dims)
    endelse
  endif else begin
    IF (n_elements((*self.data)._data) EQ 1) && $
      ~size((*self.data)._data,/n_dimensions) THEN BEGIN
      dataspace_id = H5S_CREATE_SCALAR()
    ENDIF ELSE BEGIN
      dataspace_id = H5S_CREATE_SIMPLE(size((*self.data)._data,/dimensions)>1)
    ENDELSE
  endelse

  ;; create the dataset
  dataset_id = H5D_CREATE(id,self.name,datatype_id,dataspace_id)
  ;; write the data to the dataset
  H5D_WRITE,dataset_id,(*self.data)._data
  ;; close the identifiers
  H5S_CLOSE,dataspace_id
  H5T_CLOSE,datatype_id

  ;; add any attributes
  FOR i=0,n_tags(*self.data)-1 DO BEGIN
    ;; find all structures not named _DATA
    IF ((size((*self.data).(i),/type) EQ 8) && $
        ((tag_names(*self.data))[i] NE '_DATA')) THEN BEGIN
      ;; pass a pointer instead of the data structure
      ;; save current pointer
      ptr = ptr_new(*self.data)
      ;; update data pointer
      *self.data = (*self.data).(i)
      IF (strupcase((*self.data)._type) EQ 'ATTRIBUTE') THEN BEGIN
        self.name = (tag_names(*ptr))[i]
        wh = where(tag_names(*self.data) EQ '_NAME')
        IF (wh NE -1) THEN self.name = (*self.data).(wh)
        IF ~self->h5_create_attribute(dataset_id) $
          THEN return,0
      ENDIF
      ;; restore current pointer
      *self.data = *ptr
      ptr_free, ptr
    ENDIF
  ENDFOR

  H5D_CLOSE,dataset_id

  return, 1

END

;;----------------------------------------------------------------------------
;; IDLffH5Create::H5_CREATE_IDL_CREATE_STRUCT
;;
;; Purpose:
;;   Make all the string elements in struct to be the longest of the
;;   corresponding elements in data
;;
;; Parameters:
;;   DATA - input structure
;;
;; Keywords:
;;   NONE
;;
FUNCTION IDLffH5Create::h5_create_idl_create_struct, data
  compile_opt idl2, hidden

  struct = data[0]
  FOR i=0,n_tags(struct)-1 DO BEGIN
    CASE size(struct.(i),/type) OF
      7 : struct.(i) = strjoin(replicate(' ',max(strlen(data.(i)))))
      8 : struct.(i) = self->h5_create_idl_create(data.(i))
      ELSE :
    ENDCASE
  ENDFOR

  return, struct

END

;;----------------------------------------------------------------------------
;; IDLffH5Create::H5_CREATE_IDL_CREATE
;;
;; Purpose:
;;   Create an HDF5 datatype, ensuring that the longest string in an
;;   array is used
;;
;; Parameters:
;;   DATA - input data
;;
;;   MEMBER_NAMES - names for compound data
;;
;; Keywords:
;;   NONE
;;
FUNCTION IDLffH5Create::h5_create_idl_create, data, member_names
  compile_opt idl2, hidden

  type = size(data,/type)
  IF (type EQ 7) THEN BEGIN
    str = strjoin(replicate(' ',max(strlen(data))))
    return, H5T_IDL_CREATE(str)
  ENDIF

  IF (type NE 8) THEN $
    return, H5T_IDL_CREATE(data)

  struct = self->h5_create_idl_create_struct(data)
  return, H5T_IDL_CREATE(struct, MEMBER_NAMES=member_names)

END

;;----------------------------------------------------------------------------
;; IDLffH5Create::H5_CREATE_VALIDATE_STRUCTURE
;;
;; Purpose:
;;   Ensures that the structue conforms to minimum requirements
;;
;; Parameters:
;;   PDATA - Pointer to a structure
;;
;; Keywords:
;;   NONE
;;
FUNCTION IDLffH5Create::h5_create_validate_structure, pdata
  compile_opt idl2, hidden

  valid_types = ['GROUP','DATATYPE','ATTRIBUTE','DATASET','LINK']

  wh = where(tag_names(*pdata) EQ '_TYPE')
  ;; fail if the _TYPE tag does not exist
  IF (wh EQ -1) THEN $
    return, 0
  type = strupcase((*pdata).(wh))

  ;; if the type is not an acceptable type then accept it as a valid
  ;; structure that will be ignored
  wh = where(type EQ valid_types)
  IF (wh EQ -1) THEN $
    return, 1

  ;; for all but group, check for required _DATA tag
  IF (wh GT 1) THEN BEGIN
  wh = where(tag_names(*pdata) EQ '_DATA')
  ;; fail if the _DATA tag does not exist
  IF (wh EQ -1) THEN $
    return, 0
  ENDIF

  FOR i=0,n_tags(*pdata)-1 DO BEGIN
    ;; only validate non_DATA structures
    IF ((size((*pdata).(i),/type) EQ 8) && $
        ((tag_names(*pdata))[i] NE '_DATA')) THEN BEGIN
      ;; fail if an invalid structure is found
      ptr = ptr_new((*pdata).(i))
      IF ~self->h5_create_validate_structure(ptr) THEN BEGIN
        ptr_free, ptr
        return, 0
      ENDIF
      ptr_free,ptr
    ENDIF
  ENDFOR

  return, 1

END

;;----------------------------------------------------------------------------
;; IDLffH5Create::Init
;;
;; Purpose:
;;   Creates a new HDF5 file based on a nested structure of definitions
;;
;; Parameters:
;;   FILENAME - Name (with optional path) of new file to create
;;
;;   DATA - Input structure
;;
;;   MSG - Output variable to hold the message if file creation fails
;;
;; Keywords:
;;   NONE
;;
FUNCTION IDLffH5Create::Init, filename, data, msg
  compile_opt idl2, hidden

  self.data = ptr_new(data)

  catch, err
  IF (err NE 0) THEN BEGIN
    catch,/cancel
    MESSAGE, /RESET
    msg = 'Unable to create file'
    ptr_free, [self.data,self.hardlinks]
    IF (self.fid NE 0) THEN H5F_CLOSE, self.fid
    return, 0
  ENDIF

  ;; validate structure
  IF ~self->h5_create_validate_structure(self.data) THEN BEGIN
    msg = 'Invalid data structure'
    ptr_free,self.data
    return, 0
  ENDIF

  wh = where(tag_names(data) EQ '_TYPE')
  type = strupcase(data.(wh))

  ;; only allow valid types to be attached to the file
  valid_types = ['GROUP','DATATYPE','DATASET','LINK']
  IF where(type EQ valid_types) EQ -1 THEN BEGIN
    msg = strupcase(type)+': is not a valid top level structure'
    ptr_free,self.data
    return, 0
  ENDIF

  ;; everything but a group requires a _NAME tag
  name = ''
  wh = where(tag_names(data) EQ '_NAME')
  IF (wh NE -1) THEN BEGIN
    wh2 = where(tag_names(data) EQ '_FILE')
    IF (wh2 NE -1) THEN BEGIN
      IF (data.(wh) EQ data.(wh2)) THEN BEGIN
        name = '/'
      ENDIF ELSE BEGIN
        name = data.(wh)
      ENDELSE
    ENDIF ELSE BEGIN
      name = data.(wh)
    ENDELSE
  ENDIF
  IF ((name EQ '') && (type EQ 'GROUP')) THEN name = '/'
  IF (name EQ '') THEN BEGIN
    msg = '_NAME is required when the top level structure is not a group'
    ptr_free,self.data
    return, 0
  ENDIF
  self.name = name

  ;; create file
  self.fid = H5F_CREATE(filename)

  ;; call appropriate creation routine
  CASE type OF
    'DATASET' : success = self->h5_create_dataset(self.fid)
    'DATATYPE' : success = self->h5_create_datatype(self.fid)
    'GROUP' : success = self->h5_create_group(self.fid)
    'LINK' : success = self->h5_create_link(self.fid)
    ELSE : success = 0
  ENDCASE

  ;; if something failed then close file and report an error
  IF ~success THEN BEGIN
    H5F_CLOSE, self.fid
    msg = self.msg
    ptr_free, [self.data,self.hardlinks]
    return, 0
  ENDIF

  ;; add hard links
  IF ptr_valid(self.hardlinks) THEN BEGIN
    catch, err
    IF (err NE 0) THEN BEGIN
      catch,/cancel
      MESSAGE, /RESET
      msg = 'Unable to create link: '+struct.newname
      ptr_free, [self.data,self.hardlinks]
      H5F_CLOSE, self.fid
      return, 0
    ENDIF

    FOR i=0,n_elements(*self.hardlinks)-1 DO BEGIN
      struct = (*self.hardlinks)[i]
      ;; create link
      H5G_LINK, self.fid, struct.currentname, struct.newname, $
                NEW_LOC_ID=struct.id
    ENDFOR
  ENDIF

  ;; close file
  H5F_CLOSE, self.fid
  ptr_free, [self.data,self.hardlinks]

  return, 1

END

;;----------------------------------------------------------------------------
;; IDLffH5Create__Define
;;
;; Purpose:
;;   Definition procedure for the IDLffH5Create object
;;
;; Parameters:
;;   NONE
;;
;; Keywords:
;;   NONE
;;
PRO IDLffH5Create__define
  compile_opt idl2, hidden

  void = {IDLffH5Create, $
          fid: 0l, $
          name: '', $
          msg: '', $
          data: ptr_new(), $
          hardlinks: ptr_new() $
         }
  struct = {_H5CREATELINKS, $
            id: 0l, $
            currentname: '', $
            newname: '' $
           }

END

;;----------------------------------------------------------------------------
;; H5_CREATE
;;
;; Purpose:
;;   Creates a new HDF5 file based on a nested structure of definitions
;;
;; Parameters:
;;   FILENAME - Name (with optional path) of new file to create
;;
;;   DATA - Input structure
;;
;; Keywords:
;;   NONE
;;
PRO h5_create, filename, data
  compile_opt idl2, hidden

  on_error,2

  IF (n_params() NE 2) THEN BEGIN
    message,'Incorrect number of arguments'
    return
  ENDIF

  IF ((size(filename,/type) NE 7) || (n_elements(filename) NE 1)) THEN BEGIN
    message,'Filename must be a scalar string'
    return
  ENDIF

  IF (size(data,/type) NE 8) THEN BEGIN
    message,'Input data must be a structure'
    return
  ENDIF

  oH5 = obj_new('IDLffH5Create', filename, data, msg)
  IF obj_valid(oH5) THEN obj_destroy,oH5
  IF n_elements(msg) THEN message,msg

END
