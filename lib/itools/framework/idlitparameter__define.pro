; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitparameter__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitParameter
;
; PURPOSE:
;   This class implements a parameter interface that allows names to
;   be associated with data objects. As part of this functionality,
;   parameter-data type matchings functionality is provided as well as
;   the ability to recieve updates when data values have changed.
;
;   It is expected that this class is included in other classes that
;   require a parameter interface.
;
; SUPERCLASSES:
;   None
;
;-
;;----------------------------------------------------------------------------
;; IDLitParameter::Init
;;   This function method initializes the IDLitParameter object.
;;
;; CALLING SEQUENCE:
;;   Obj = OBJ_NEW('IDLitParameter')
;;       or
;;   Result = Obj->[IDLitParameter::]Init()
;;
function IDLitParameter::Init,_REF_EXTRA=_ref_extra

   compile_opt idl2, hidden

   ;; Create the container which will be used to store the
   ;; ParameterDescriptor list.
   self._oParameterDescriptors = OBJ_NEW('IDL_Container')
   if not OBJ_VALID(self._oParameterDescriptors) then $
     return, 0                  ; failure
   ;; Create a parameter set to manage the actual data registered with
   ;; this class. While the parameter descriptor container contains
   ;; the parameter that this object suports, the parameter set
   ;; contains the data that has been associated with these parameters.
   self._oParameterSet = OBJ_NEW('IDLitParameterSet',name="Parameters", _parent=self)
   if ~OBJ_VALID(self._oParameterSet) then begin
       obj_destroy, self._oParameterDescriptors
       return, 0                ; failure
   endif

   ;; We maintain a list of names for the parameters registered with
   ;; this class for ease of use.
   self._pParamNames = PTR_NEW(/ALLOC)

   return, 1                    ; success
end


;;----------------------------------------------------------------------------
;; IDLitParameter::Cleanup
;;
;; Purpose
;;    This procedure method performs all cleanup on the object.
;;
;; Parameters:
;;    None.

pro IDLitParameter::Cleanup
    compile_opt idl2, hidden

    ;; Break the connection with the data objects associated with this
    ;; class
    self->IDLitParameter::_DisconnectParameters
    ;; free memory
    PTR_FREE, self._pParamNames
    if (OBJ_VALID(self._oParameterSet)) then $
        self._oParameterSet->Remove, /ALL
    obj_destroy, self._oParameterSet
    OBJ_DESTROY, self._oParameterDescriptors
end
;;---------------------------------------------------------------------------
;; IDLitParameter::_DisconnectParameters
;;
;; Purpose:
;;   Internal routine used to disconnect the data connected to the
;;   parameters
;;
;; Parameters:
;;   None.
PRO IDLitParameter::_DisconnectParameters
   compile_opt hidden, idl2

   ; No parameters.
   if (~OBJ_VALID(self._oParameterSet)) then $
    return

   ;; Disconnect from the data objects.
   ;; Disconnect all the parameters first, before autodeleting,
   ;; otherwise an object in the process of being destroyed may get
   ;; an update data notification via one of the other parameters.
   oData = self._oParameterSet->Get(/all, count=nData, name=names)
   for i=0, nData-1 do begin
        if (~OBJ_VALID(oData[i])) then $
            continue
       oData[i]->RemoveDataObserver, self, /NO_AUTODELETE
   endfor
   for i=0, nData-1 do begin
        if (~OBJ_VALID(oData[i])) then $
            continue
        oData[i]->RemoveDataObserver, self
        if (names[i] eq '') then $
            continue
       ;; Destroy the data of any by value parameters
       self->GetParameterAttribute, names[i], BY_VALUE=by_value
       if(by_value)then $
         obj_destroy,oData[i]
   endfor
end


;----------------------------------------------------------------------------
; IDLitParameter::QueryParameter
;
; Purpose
;   This function method checks whether a parameter is registered,
;   or retrieves a list of all registered parameters.
;
; Return value:
;   Returns a 1 if Parameter is a scalar string that corresponds
;   to a valid registered parameter, or a 0 otherwise.
;   If Parameter is an array, the result is an array of 1s and 0s.
;   If Parameter is not specified, Result is a string array containing
;   the names of all registered parameters.
;
; Arguments:
;   Parameter: A scalar string or string array containing parameter names.
;
; Keywords:
;   COUNT: If Parameter is not supplied, then COUNT contains the number
;       of registered parameters. If Parameter is supplied then COUNT
;       contains the total number of matched parameters.
;
function IDLitParameter::QueryParameter, ParamNamesIn, COUNT=COUNT

    compile_opt idl2, hidden

    count = N_ELEMENTS(*self._pParamNames)

    ; No argument, just return all registered parameters.
    if (N_PARAMS() eq 0) then $
        return, (count gt 0) ? *self._pParamNames : ''

    nparam = N_ELEMENTS(ParamNamesIn)
    result = LONARR(nparam)

    ; No registered parameters, return an array of zeroes.
    if (count eq 0) then $
        return, result

    ; Loop thru each supplied parameter and see if it's registered.
    for i=0,nparam-1 do begin
        result[i] = MAX(*self._pParamNames eq STRUPCASE(ParamNamesIn[i]))
    endfor

    ; Total number of matches.
    count = TOTAL(result, /INTEGER)

    return, result

end


;----------------------------------------------------------------------------
;; IDLitParameter::QueryParameterDescriptor
;;
;; Purpose
;;   This function method returns ParameterDescriptor object
;;   references.
;;
;; Parameters:
;;   ParamNamesIn    - The names to return descriptors for. If no name
;;                     is provided, all descriptors are returned.
;;
;; Keywords:
;;   COUNT           - The number of items returned
;;
;; Return Value:
;;   The matching parmeter descriptors requested or a null obj ref.

function IDLitParameter::QueryParameterDescriptor, ParamNamesIn, $
                       COUNT=COUNT

   compile_opt idl2, hidden

    ; Sanity check.
    if (~OBJ_VALID(self._oParameterDescriptors)) then begin
        count = 0
        return, OBJ_NEW()
    endif

   ;; Parameter check
   oParamDesc = self._oParameterDescriptors->Get(/ALL, count=count)
   if (N_PARAMS() lt 1) then $
      return, (count gt 0) ? oParamDesc : OBJ_NEW()

   ;; Construct Result variable
   ParamNames = STRUPCASE(ParamNamesIn)
   nParam = N_ELEMENTS(ParamNames)

   ;; Loop thru each stored ParameterDescriptor, see if name matches one of the
   ;; requested names. More efficient to do loop over all stored objrefs,
   ;; so we only have to do GetProperty once.
   if(n_elements(*self._pParamNames) gt 0)then begin;; do we have parameters at all
       for i=0, nParam-1 do begin
           ;; Do we have a name match?
           dex = where(ParamNames[i] eq *self._pParamNames, nMatch)
           if(nMatch gt 0)then $
             dexMatch = (n_elements(dexMatch) gt 0 ? $
                         [dexMatch, dex[0]] : dex[0])
       endfor
   endif
   count = n_elements(dexMatch)
   return, (count gt 0 ? oParamDesc[dexMatch] : obj_new())
end


;;----------------------------------------------------------------------------
;; IDLitParameter::RegisterParameter
;;
;; Purpose:
;;   This procedure method registers a paramete with the parameter
;;   interface.
;;
;;   When called, this routine will add the new parameter's name to
;;   the internal list of registered parameters and add the associated
;;   parameter descriptor that is created to the internal parameter list.
;;
;; Parameters:
;;   Name  - The name of the parameter to add to the system. If this
;;           name already exists in the parameter this, this routine
;;           will return quiety.
;;
;; Keywords:
;;    All keywords are passed to the underlying paramete descriptor object.
;
pro IDLitParameter::RegisterParameter, strName, _EXTRA=_extra

   compile_opt idl2, hidden

   ;; See if this parameter is already registered with the given
   ;; parameter set.
   tmpName = strupcase(strName)
   if (n_elements(*self._pParamNames) gt 0) then begin
        index = WHERE(*self._pParamNames eq $
                      tmpName, nMatch)
        if(nMatch gt 0)then return ;; cannot replace existing parameters
        strOrig = *self._pParamNames ;; for roll-back
        *self._pParamNames = [TEMPORARY(*self._pParamNames), tmpName]

    endif else $            ; Start a new list
        *self._pParamNames = tmpName

   oDesc = obj_new('IDLitParameterDescriptor', NAME=strName, $
                   _extra=_extra)

   if(obj_valid(oDesc))then $
     self._oParameterDescriptors->Add, oDesc $
   else if(n_elements(strOrig) gt 0)then $
        *self._pParamNames = strOrig
end


;---------------------------------------------------------------------------
; IDLitParameter::GetParameterAttribute
;
; Purpose
;   This procedure method retrieves one or more parameter attributes
;   for a registered parameter.
;
; Arguments:
;   Parameter: A scalar string containing the parameter name.
;
; Keywords:
;   Any keywords to the IDLitParameter::RegisterParameter method
;   can be retrieved.
;
pro IDLitParameter::GetParameterAttribute, parameter, _REF_EXTRA=_extra

   compile_opt idl2, hidden

@idlit_on_error2

    ; Find the IDLitParameterDescriptor object.
    oDesc = self->QueryParameterDescriptor(parameter)
    if (~OBJ_VALID(oDesc)) then begin
        Message, IDLitLangCatQuery('Error:Framework:BadParam') + $
            parameter
        return
    endif

    oDesc->GetProperty, _STRICT_EXTRA=_extra

end


;---------------------------------------------------------------------------
; IDLitParameter::SetParameterAttribute
;
; Purpose
;   This procedure method sets one or more parameter attributes
;   for a registered parameter.
;
; Arguments:
;   Parameter: A scalar string or string array containing parameter names.
;       If Parameter is an array then the attribute values are set
;       on all specified parameters.
;
; Keywords:
;   Any keywords to the IDLitParameter::RegisterParameter method can be set.
;
pro IDLitParameter::SetParameterAttribute, parameters, _EXTRA=_extra

   compile_opt idl2, hidden

@idlit_on_error2

    for i=0,N_ELEMENTS(parameters)-1 do begin
        ; Find the IDLitParameterDescriptor object.
        oDesc = self->QueryParameterDescriptor(parameters[i])
        if (~OBJ_VALID(oDesc)) then begin
            Message, IDLitLangCatQuery('Error:Framework:BadParam') + $
                parameters[i]
            return
        endif
        oDesc->SetProperty, _STRICT_EXTRA=_extra
    endfor

end


;;----------------------------------------------------------------------------
;; IDLitParameter::GetParameter
;;
;; Purpose:
;;   This function method retrieves the data object reference
;;   associated with a parameter using the parameters name.
;;
;; Parameters:
;;   ParamName   -  A string giving the ParameterDescriptor name
;;                  whose object reference should be retrieved.
;;
;; Keywords:
;;   ALL        - If set, all items are returned.
;;
;;   COUNT[out] - The number of items returned.
;;
;;   OPTARGETS - If set, return only the data objects for
;;     parameters that are operation targets.  This keyword
;;     takes precedence over the ALL keyword.
;;
;; Return Value
;;     The data object reference associated with the parameter. If the
;;     given value is not contained by this object, a null object
;;     reference is returned and a count of 0 is returned.
function IDLitParameter::GetParameter, ParamName, $
    ALL=ALL, $
    COUNT=COUNT, $
    OPTARGETS=opTargets

    compile_opt idl2, hidden

    if (keyword_set(opTargets)) then begin
        oData = self._oParameterSet->Get(/ALL, NAME=names, COUNT=nData)
        if (nData eq 0) then $
            return, OBJ_NEW()

        count = 0
        for i=0,nData-1 do begin
            if (names[i] eq '') then $
                continue
            self->GetParameterAttribute, names[i], OPTARGET=isOpTarget
            if (isOpTarget) then begin
                opTargets = count ? [opTargets, oData[i]] : oData[i]
                count++
            endif
         endfor
         return, opTargets
    endif

    if(keyword_set(all)) then $
       return, self._oParameterSet->Get(/all, count=count)

    if(not keyword_Set(ParamName))then begin
        count=0
        return, obj_new()
    endif
    return, self._oParameterSet->GetByName(ParamName, count=count)

end

;;----------------------------------------------------------------------------
;;  IDLitParameter::GetParameterName
;;
;; Purpose:
;;    This function method retrieves the parameter name associated with
;;    an data object reference (reverse lookup).
;;
;; Parameters:
;;   oParam     - An data object reference whose name should be retrieved.
;;
;; Keywords:
;;   None.
;;
;; Return Value:
;;     - The name of the given parameter data object. If this object
;;       is not contained, a empty string is returned ('').
;
; KEYWORD PARAMETERS:
;   None.
;-
function IDLitParameter::GetParameterName, oParam

    compile_opt idl2, hidden

    if (N_PARAMS() lt 1) || ~OBJ_VALID(self._oParameterSet) then $
      return, ''

    ;; Just call into the parameter set.
    status = self._oParameterSet->GetParameterName(oParam, strName)
    return, (status eq 1 ? strName : '')
end

;;----------------------------------------------------------------------------
;; IDLitParameter::SetParameter
;;
;; Purpose:
;;   This procedure method associates a data object with the given
;;   parameter.
;;
;; Parameters:
;;    ParamName    - The name of the parameter to set
;;
;;    oItem        - The IDLitData object to associated with the given
;;                   parameter.
;;
;; Keywords:
;;    BY_VALUE - Used to indicate that the parameter is by_value. IF
;;               not set, the current setting for the parameter is used.

pro IDLitParameter::SetParameter, ParamName, oData, $
    BY_VALUE=BY_VALUE, NO_UPDATE=noUpdate
    compile_opt idl2, hidden

    if(not obj_isa(oData, "IDLitData"))then return

    nReg = N_ELEMENTS(*self._pParamNames)
    if(nReg eq 0)then return

    ;; First step, make sure that this parameter matches one
    ;; registered.
    strName = strupcase(ParamName)
    dex = where(*self._pParamNames eq  strName, nMatch)
    if(nMatch eq 0)then $
      return

    ; Retrieve the previous parameter value.
    oOldMatch = self._oParameterSet->GetByName(strName)

    ; Send OnDataDisconnect notification if replacing old parameter.
    if (OBJ_VALID(oOldMatch) && ~KEYWORD_SET(noUpdate)) then $
        self->OnDataDisconnect, strName


    ;; Check if we have a new by_value setting?
    if (N_ELEMENTS(by_value)) then begin
        ;; new settings, change the desc.
        self->SetParameterAttribute, ParamName, BY_VALUE=by_value
    endif else begin
       ; Retrieve the current BY_VALUE setting for this parameter.
        self->GetParameterAttribute, ParamName, BY_VALUE=by_value
    endelse

    ;; Add this to the parameter set. This will overwrite/remove the
    ;; above item. Note: do not change the location of the data object
    ;; being added.
    self._oParameterSet->Add, oData, parameter_name=strName, $
                         preserve_location=(~ keyword_set(by_value))

    ;; Establish Subject-Observer relationship.
    ;; Note: For future development, this should only happen on input
    ;; parameters. However, since this is all that is currently
    ;; supported, the connection is just done directly.
    oData->AddDataObserver, self

    ; If the old data item is still being used, then
    ; don't want to destroy it or break the subject-observer link.
    if (OBJ_VALID(oOldMatch) && $
        ~self._oParameterSet->IsContained(oOldMatch)) then begin
        ; If by_value then we can safely destroy the old object.
        oOldMatch->GetProperty, BY_VALUE=by_value
        if (by_value) then begin
            obj_destroy, oOldMatch
        endif else begin
            oOldMatch->RemoveDataObserver, self
        endelse
    endif


    ; Should we notify the user?
    if (~keyword_set(noUpdate)) then $
        self->OnDataChangeUpdate, oData, strName

end

;;----------------------------------------------------------------------------
;; IDLitParameter::UnsetParameter
;;
;; Purpose:
;;    This mehtod breaks the relationship between a parameter and the
;;    data object associated with ti.
;;
;; Parameters:
;;   ParamName    - The name of the parameter that should have it's
;;                  data object removed from this object.
;; Keywords:
;   None.
;
pro IDLitParameter::UnsetParameter, ParamName, NO_UPDATE=noUpdate

    compile_opt idl2, hidden

    if(not keyword_set(paramName))then return
    upName = strupcase(ParamName)
    oMatch = self._oParameterSet->GetByName(upName,count=nMatch, $
        POSITION=iMatch)

    if(nMatch eq 0)then return

    ; Remove the data item from the parameter set. Do this by position
    ; in case the data item is used for multiple parameters.
    self._oParameterSet->Remove, POSITION=iMatch

    ; If this data item was being used for multiple parameters, then
    ; don't want to break the subject-observer link.
    ; Otherwise, break it.
    if (~self._oParameterSet->IsContained(oMatch)) then $
        oMatch->RemoveDataObserver, self

    ;; Is this a by_value parameter?
    self->GetParameterAttribute, upName, BY_VALUE=by_value
    if(by_value)then $
        obj_destroy, oMatch

    ;; Call the onDataDisconnect method
    if (~KEYWORD_SET(noUpdate)) then $
        self->OnDataDisconnect, upName
end

;;---------------------------------------------------------------------------
;; IDLitParameter::GetOpTargets
;;
;; Purpose:
;;  Return the descriptors that are operation targets
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   COUNT -  The number of operation target objects returned.
;;
;; Return Value
;;   null - no op target.
;;
;;   target descriptors

function IDLitParameter::GetOpTargets, COUNT=COUNT

   compile_opt idl2, hidden

   ;; Basically walk through our parameter descriptor list and get all
   ;; the operation targets
   if OBJ_VALID(self._oParameterDescriptors) then $
       oParams = self._oParameterDescriptors->Get(/all, count=nParams) $
   else nParams = 0
   for i=0, nParams-1 do begin
       oParams[i]->GetProperty, OPTARGET=op_targ
       if(op_targ ne 0)then $
           oTargets =  (n_elements(oTargets) gt 0 ? $
                        [oTargets, oParams[i]] : oParams[i])
   endfor
   count = n_elements(oTargets)
   return, (count gt 0 ? oTargets : obj_new())
end

;;---------------------------------------------------------------------------
;; IDLitParameter::GetParameterTypes
;;
;; Purpose:
;;   Returns all the data types supported by this parameter set.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   COUNT    - Number of types returned.
;;
;; Return Value:
;;   The types supported (no duplicates contained). If no types
;;   specified or no op targets exist, '' is returned and count is 0.
;;
function IDLitParameter::GetParameterTypes, COUNT=COUNT

   compile_opt hidden, idl2

   oParams = self->GetOpTargets(count=nParams)

   COUNT=0
   if(nParams eq 0)then $
     return, ''

   types = ''
   for i=0, nParams-1 do begin
       oParams[i]->GetProperty, TYPES=parmTypes
       if(n_elements(parmTypes) gt 0)then  $
           types = [types, parmTypes]
   endfor
   nTypes = n_elements(types)
   if(nTypes eq 1)then begin
       types = ''
       count = 0
   endif else begin
       types = types[1:*]
       types = types[uniq(types, sort(types))]
       count = n_elements(types)
   endelse
   return, types
end

;;----------------------------------------------------------------------------
;; IDLitParameter::SetData
;;
;; Purpose:
;;   This function method sets the data of one of the parameters of this
;;   parameter inteface to the data within the given data object.
;;
;;   The parameter for which the data is set is determined by the
;;   following:
;;     - If a parameter name is provided, data is associated with it.
;;     - If no parameter name is provided, the provided data type is
;;       used to determine which arguement to associated with. When
;;       this is preformed, the search begins with the first object
;;       associated with this interface that is an op-target.
;;
;;   When a parameter match is found, the given data object is
;;   associted with the matching parameter.
;;
;;   Parameters:
;;     oData   - The data object being associated with this.
;;
;;   Keywords:
;;      BY_VALUE      - Set this keyword to a nonzero value if the data
;;                      is to be set by value.  By default, the data
;;                      is set by reference.
;;
;;      PARAMETER_NAME- Set this keyword to a string representing the
;;                      name of the target parameter.  By default, the
;;                      default parameter is used (if the type
;;                      matches) or a parameter with the matching
;;                      type is used.
;;
;;      NO_UPDATE     - Normally, when a parameter is associated with
;;                      a data object, the OnDataChangeUpdate method
;;                      on this object (which should be overridden) is
;;                      called to notify that the parameter has been
;;                      updated. By setting this keyword, this call is
;;                      skipped.  THIS IS FOR INTERNAL USE ONLY
;;
;;   Return Value
;;       This function returns a 1 on success, or 0 otherwise.

function IDLitParameter::SetData, oData, $
                       BY_VALUE=BY_VALUE, $
                       PARAMETER_NAME=PARAMETER_NAME, $
                       NO_UPDATE=NO_UPDATE

   compile_opt idl2, hidden

   if (not obj_valid(oData)) then return, 0

   ;; First get the parameters we can search. This keys off the idea
   ;; that a parameter name was provided.
   if(keyword_set(PARAMETER_NAME))then begin
        valid = self->QueryParameter(PARAMETER_NAME, COUNT=nParams)
        if (~nParams) then $
            return, 0
        parameters = PARAMETER_NAME[WHERE(valid)]
   endif else begin
        parameters = self->QueryParameter(COUNT=nParams)
        if (~nParams) then $
            return, 0
        optargets = BYTARR(nParams)
        for i=0,nParams-1 do begin
            self->GetParameterAttribute, parameters[i], OPTARGET=isOpTarget
            optargets[i] = isOpTarget
        endfor
        isop = WHERE(optargets, nops)
        if (nops gt 0) then $
            parameters = parameters[isop]
   endelse

   nMatch=0

   for i=0, N_ELEMENTS(parameters)-1 do begin

       ;; Make sure this parameter isn't already in the match array.
       if (nMatch gt 0 && MAX(matchParam eq parameters[i])) then $
             continue ;; already done

       ;; What types does this parameter take?
       self->GetParameterAttribute, parameters[i], TYPES=destTypes

       ;; Get the list of data  objects that match this type.
       oSubData = oData->GetByType(destTypes)
       dxValid = where(obj_valid(oSubData) eq 1, nData) ;any valid data?
       if(nData eq 0)then $
         continue   ;; no matching data, next parameter

       ;; Add the first matching data element to the match list.
       oSubData = oSubData[dxValid]
       if(nMatch eq 0)then begin
           nMatch = 1
           matchParam = parameters[i]
           oMatchData = oSubData[0]
       endif else begin
           ;; Make sure we haven't used this data yet.
           for iData=0, nData-1 do begin
               dex = where(oMatchData eq oSubData[iData], cnt)
               ;; If this data is not in the match list, add it and
               ;; break out of this inner loop.
               if(cnt eq 0)then begin
                   nMatch++     ;
                   matchParam = [matchParam, parameters[i]]
                   oMatchData =  [oMatchData, oSubData[iData]]
                   break
               endif
           endfor
       endelse ;; > 1 in match list.
   endfor


    ; Now determine which parameters have data already associated with
    ; them. Default behavior is to skip these (ie don't overwrite)
    ; unless a parameter name was provided.
    if (~KEYWORD_SET(parameter_name)) then begin
        nTmp = nMatch
        nMatch = 0
        for i=0, nTmp-1 do begin
            oDataParam = self->IDLitParameter::GetParameter(matchParam[i], $
                COUNT=cnt)
            ; If a parameter name was sepecified, we will use it.
            ; The set parameter call will manage any collisions
            if (cnt eq 0) then begin
                oMatchData[nMatch] = oMatchData[i]
                matchParam[nMatch] = matchParam[i]
                nMatch++
            endif
        endfor
    endif

    ; Did we get any matches?
    if (nMatch eq 0) then $
        return, 0

   ;; Time to make the data associations.
   for i=0, nMatch-1 do begin
        ; Set this data to the parameter and set the byvalue
        ; setting. Also this will associated the data to this object.
        self->SetParameter, matchParam[i], oMatchData[i], $
            BY_VALUE=keyword_set(by_value), $
            NO_UPDATE=NO_UPDATE
   endfor

   return,1
end


;;---------------------------------------------------------------------------
;; IDLitParameter::OnDataDisconnect
;;
;; Purpose:
;;   This function method handles notification that the data for a
;;   given parameter is disconnected from that parameter
;;
;;   For this class, this is a no-op and just defines the interface
;;   and provides a method if the user fails to implement one.
;;
;; Parameters:
;;   ParmName    - A string representing the name of the
;;                 disconnected parameter.
;-
pro IDLitParameter::OnDataDisconnect, parmName
  compile_opt idl2, hidden

  ;; NO-OP

end

;;---------------------------------------------------------------------------
;; IDLitParameter::OnDataChangeUpdate
;;
;; Purpose:
;;   This function method handles notification that the data for a
;;   given parameter has changed.
;;
;;   For this class, this is a no-op and just defines the interface
;;   and provides a method if the user fails to implement one.
;;
;; Parameters:
;;   Subject     - A reference to the object sending
;;                 notification of the data change.
;;
;;   ParmName    - A string representing the name of the
;;                 changed parameter.
;-
pro IDLitParameter::OnDataChangeUpdate, oSubject, parmName
  compile_opt idl2, hidden

  ;; NO-OP

end

;;----------------------------------------------------------------------------
;; IDLitParameter::OnDataChange
;;
;; Purpose:
;;   This procedure method handles notification that the data has
;;   changed. When called, if the given data item is associated with a
;;   parameter, the OnDataChangeUpdate() method is called on this object.
;;
;; Parameters:
;;   oSubject    - The data object that was updated.
pro IDLitParameter::OnDataChange, oSubject

    compile_opt idl2, hidden

    ;; Get the parameter name and if valid, call
    if( obj_valid(oSubject))then begin
        parmName = self->IDLitParameter::GetParameterName(oSubject)
        if (parmname[0] ne '') then begin
            for i=0,N_ELEMENTS(parmName)-1 do $
                self->OnDataChangeUpdate, oSubject, parmName[i]
        endif
    endif
end
;;---------------------------------------------------------------------------
;; IDLitParameter::OnDataComplete
;;
;; Purpose:
;;   This function method handles notification that the data for a
;;   given parameter has changed. This is just a stub, since nothing
;;   is required at this point by this interface
;;
;; Parameters:
;;   Subject     - A reference to the object sending
;;                 notification of the data change.
pro IDLitParameter::OnDataComplete, oSubject
  compile_opt idl2, hidden

  ;; NO-OP

end

;;----------------------------------------------------------------------------
;; IDLitParameter::OnDataDelete
;;
;; Purpose:
;;   This procedure method handles notification that the data has
;;   been delete. When called, if the given data item is associated with a
;;   parameter, the OnDataDisconnect() method is called on this object.
;;
;; Parameters:
;;   oSubject    - The data object that was updated.
pro IDLitParameter::OnDataDelete, oSubject

    compile_opt idl2, hidden
    ;; Get the parameter name and if valid, call
    if( obj_valid(oSubject))then begin
        parmName = self->IDLitParameter::GetParameterName(oSubject)
        if (parmname[0] ne '') then begin
            for i=0,N_ELEMENTS(parmName)-1 do $
                self->OnDataDisconnect, parmName[i]
        endif
        ;; Now remove the data item from all of our parameterest
        self._oParameterSet->Remove, oSubject

    endif
end

;;---------------------------------------------------------------------------
;; IDLitParameter::GetParameterDataByType
;;
;; Purpose:
;;   This function method retrieves the data (associated with this
;;   set of parameters) that matches the given data types.
;;
;; Parameters:
;;    srcTypes    - The data type to search for.
;;
;;    oDataObjs   - A name variable that upon return will contain data
;;                  objects that match the given type.
;;
;; Return Value
;;    The number of matching parameters found. If 0, DataObjs is undefined.

function IDLitParameter::GetParameterDataByType, srcTypes, oDataObjs
   compile_opt idl2, hidden

   ;; Okay, get all of the parameters
    parameters = self->QueryParameter(COUNT=nparam)
    if (~nparam) then $
        return, 0

    ; Okay, at this point we need to find the target parameter and the
    ; the data objects
    nData = 0
    for i=0, nparam-1 do begin
        oData = self->GetParameter(parameters[i])
        if (obj_valid(oData)) then begin
            oDataTmp = (nData eq 0 ? oData : [oDataTmp ,oData])
            nData++
        endif
    endfor

   ;; Okay, we now have all of the valid data objects. Now get the
   ;; data of the correct type.
   nReturn =0
   for i=0, nData-1 do begin
       oDataTmp[i]->GetProperty, TYPE=destType
       dex = where(srcTypes eq destType, nMatch)
       if(nMatch gt 0)then begin
           oDataObjs = (nReturn gt 0 ? [oDataObjs, oDataTmp[i]] : oDataTmp[i])
           nReturn++
       endif else begin
           ;; Does the data object contain any of these types?
           oSubData = oDataTmp[i]->GetByType(srcTypes)
           if(obj_valid(oSubData[0]))then begin
               oDataObjs = (nReturn gt 0 ? [oDataObjs, oSubData] : oSubData)
               nReturn = nReturn  + n_elements(oSubData)
           endif
       endelse
   endfor
   return, nReturn
end

;;----------------------------------------------------------------------------
;; IDLitParameter::GetParameterSet
;;
;; Purpose:
;;   Returns the parameter set being used by this object. This is the
;;   internal parameter set, unless the copy keyword is used. When a
;;   copy is requested, the entire contents of the set are returned.
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;   COPY        - Create a new parameter set, but use the same
;;                 internal data objects
;;
;;   DEEP_COPY   - Make a copy of the entire parameter set, including
;;                 the data
;;
;; Return Value
;;   The requested parameter set.

function IDLitParameter::GetParameterSet, COPY=COPY, DEEP_COPY=DEEP_COPY

  compile_opt hidden, idl2

  if(keyword_set(COPY))then begin
      ;; Okay, we need to construct the parameter set and
      ;; only copy by value items.
      oCopy = obj_new("IDLitParameterSet", name="Data")
      oItems = self._oParameterSet->Get(/All, count=nItems, name=names)
      for i=0, nItems-1 do begin
        ; CT Note: The comment above says we only copy by_value items,
        ; but there is no check here for by_value! Not sure if it should
        ; be only copying by_value or not...
          oCopy->Add, oItems[i], parameter_name=names[i], /preserve_location
      endfor

  endif else if(keyword_set(DEEP_COPY))then begin
      ;; This is easy
      oCopy=  self._oParameterSet->Copy()
  endif else $
      oCopy= self._oParameterSet
  return, oCopy
end
;;----------------------------------------------------------------------------
;; IDLitParameter::SetParameterSet
;;
;; Purpose:
;;   Given a parameter set object, this method will associate the
;;   contents of the parameter set with the parameters contained in
;;   this object.
;;
;;   This is accomplished using the following scheme:
;;      - All current parameters are dis-associated.
;;      - All contents with names are set using these names via set
;;        data.
;;      - If any parameters are not matched in the set, they are set
;;        using the data matching functionality of the SetData method.
;;      - All non-matching parameters are then added as aux data to
;;        the interface (TODO: Should this be true?).
;;
;;   Note: This method does not delete or use the provided parameter
;;   set, and as such, it is the callers resposibility to free it.
;;
;; Parameters:
;;     oParamSet     - The parameter set being set. If this set
;;                     conains no elements nothing is done.
;;
;; Return Value:
;;     1 - Ok
;;     0 - Error in the set. No parameters were associated
;;
function IDLitParameter::SetParameterSet, oParamSet

    compile_opt idl2, hidden

    ;; First step is to see what this parameter set contains
    oParms=oParamSet->Get(/All, count=nParms, name=names)
    if(nParms eq 0)then $
      return, 1

    ;; Disconnect all of our parameters that currently exist.
    self->IDLitParameter::_DisconnectParameters

    oParamSet->IDLitComponent::GetProperty, NAME=paramSetName
    if (STRLEN(paramSetName) gt 0) then $
        self._oParameterSet->IDLitComponent::SetProperty, NAME=paramSetName

    iAux = where(names eq '', nAux, $
                 complement=iData, ncomplement=nData)
    ;; First step is to set the data using parameter names
    ;; Note: updates are not tiggered until after all parameters are
    ;; associated.
    if(nData gt 0)then begin ;; name parameters
        oData = oParms[iData]

        bSet = bytarr(nData) ;; to keep track of sets.
        for i=0, nData-1 do $
          bSet[i] = self->IDLitParameter::SetData(oData[i], $
                                              /NO_UPDATE, $
                                              parameter_name=names[iData[i]])
        ;; Anything not set
        iUnSet = where(bSet ne 1, nUnSet)

        ;; Okay, we now need to set the unnamed data
        if(nUnSet gt 0)then begin
            bSet = bytarr(nUnSet)
            for i=0, nUnSet-1 do $
              bSet[i] = self->IDLitParameter::SetData(oData[iUnSet[i]], /NO_UPDATE)

            ;; Any remaining items? Add them as aux data
            iUnSet2 = where(bSet ne 1, nUnSet)
            if(nUnSet gt 0)then $
              self._oParameterSet->AddAuxiliaryData, oData[iUnSet[iUnSet2]], $
                                                     /PRESERVE_LOCATION
        endif
    endif
    ;; Do we have any passed in auxiliary data?
    if(nAux gt 0)then $
      self._oParameterSet->AddAuxiliaryData, oParms[iAux], /PRESERVE_LOCATION

    ;; Now pass this to the underlying OnDataChange update routine
    self->OnDataChangeUpdate, self._oParameterSet, "<PARAMETER SET>"


    return, 1
end
;;---------------------------------------------------------------------------
;; IDLitParameter::AddAuxiliaryData
;;
;; Purpose:
;;   This method is used to add auxiliary data to the parameter
;;   set. Auxiliary data is data that doesn't have a parameter name
;;   associated with it, but is desired to be associated with the
;;   parameter set.
;;
;;   Auxiliary data is stored in the parameter set with other data
;;   values, but with the name associated with it set to ''.
;;
;; Parameters:
;;    oData   - The data objects being added.
;;
;; Keywords:
;;   None.
PRO IDLitParameter::AddAuxiliaryData, oData, $
                     PRESERVE_LOCATION=PRESERVE_LOCATION

   compile_opt hidden, idl2

   ;; Just call the add method with name = ''

   self._oParameterSet->IDLitParameterSet::AddAuxiliaryData, oData, $
     PRESERVE_LOCATION=PRESERVE_LOCATION

end

;;---------------------------------------------------------------------------
;; IDLitParameter::GetAuxiliaryData
;;
;; Purpose:
;;   This method will return auxiliary data that is contained in this
;;   parameter set. Auxiliary data is determined by those items with
;;   names marked as ''.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   COUNT[out]  - The number of items returned.
;;
;; Return Value
;;   The auxiliary data items  or obj NULL if none are contained

function IDLitParameter::GetAuxiliaryData, COUNT=COUNT
   compile_opt hidden, idl2

   return, self._oParameterSet->IDLitParameterSet::GetAuxiliaryData(count=count)
end

;;----------------------------------------------------------------------------
;; IDLitParameter__define
;;
;; Purpose:
;;   Definition for this  class.
;;
;; Instance Data
;;   _oParameterDescriptors
;;       The list (container) of parameters registered with this class
;;
;;   _oParameterSet
;;       The parameter set for this parameter list. This contains all
;;       the data that has been associated with this interface
;;
;;   _pParamNames
;;       List of parameters registered with this class. This is just
;;       used for performance.
;;
pro IDLitParameter__define

    compile_opt idl2, hidden

    struct = {IDLitParameter, $
              _oParameterDescriptors     : obj_new(), $ ;; descs for reg params
              _oParameterSet             : obj_new(), $ ;; The parameter set (active)
              _pParamNames               : ptr_new()  $ ;; Names of parameters reg.
             }
end
