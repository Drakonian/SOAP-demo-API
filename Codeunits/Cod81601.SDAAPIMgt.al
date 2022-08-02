codeunit 81601 "SDA API Mgt"
{
    //Generic codeunit to send http requests
    procedure SendRequest(RequestMethod: enum "Http Request Type"; requestUri: Text): text
    var
        DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper";
        DictionaryContentHeaders: Codeunit "Dictionary Wrapper";
        ContentType: Text;
    begin
        exit(SendRequest('', RequestMethod, requestUri, ContentType, 0, DictionaryContentHeaders, DictionaryDefaultHeaders));
    end;

    procedure SendRequest(contentToSend: Variant; RequestMethod: enum "Http Request Type"; requestUri: Text; ContentType: Text): text
    var
        DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper";
        DictionaryContentHeaders: Codeunit "Dictionary Wrapper";
    begin
        exit(SendRequest(contentToSend, RequestMethod, requestUri, ContentType, 0, DictionaryContentHeaders, DictionaryDefaultHeaders));
    end;

    procedure SendRequest(contentToSend: Variant; RequestMethod: enum "Http Request Type"; requestUri: Text; ContentType: Text; DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper"): text
    var
        DictionaryContentHeaders: Codeunit "Dictionary Wrapper";
    begin
        exit(SendRequest(contentToSend, RequestMethod, requestUri, ContentType, 0, DictionaryContentHeaders, DictionaryDefaultHeaders));
    end;

    procedure SendRequest(contentToSend: Variant; RequestMethod: enum "Http Request Type"; requestUri: Text; ContentType: Text; HttpTimeout: integer; DictionaryContentHeaders: Codeunit "Dictionary Wrapper"; DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper"): text
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        Content: HttpContent;
        ResponseText: Text;
        ErrorBodyContent: Text;
        TextContent: Text;
        InStreamContent: InStream;
        i: Integer;
        KeyVariant: Variant;
        ValueVariant: Variant;
        HasContent: Boolean;
    begin
        case true of
            contentToSend.IsText():
                begin
                    TextContent := contentToSend;
                    if TextContent <> '' then begin
                        Content.WriteFrom(TextContent);
                        HasContent := true;
                    end;
                end;
            contentToSend.IsInStream():
                begin
                    InStreamContent := contentToSend;
                    Content.WriteFrom(InStreamContent);
                    HasContent := true;
                end;
            else
                Error(UnsupportedContentToSendErr);
        end;

        if HasContent then
            Request.Content := Content;

        if ContentType <> '' then begin
            ContentHeaders.Clear();
            Request.Content.GetHeaders(ContentHeaders);
            if ContentHeaders.Contains(ContentTypeKeyLbl) then
                ContentHeaders.Remove(ContentTypeKeyLbl);

            ContentHeaders.Add(ContentTypeKeyLbl, ContentType);
        end;

        for i := 0 to DictionaryContentHeaders.Count() do
            if DictionaryContentHeaders.TryGetKeyValue(i, KeyVariant, ValueVariant) then
                ContentHeaders.Add(Format(KeyVariant), Format(ValueVariant));

        Request.SetRequestUri(requestUri);
        Request.Method := Format(RequestMethod);

        for i := 0 to DictionaryDefaultHeaders.Count() do
            if DictionaryDefaultHeaders.TryGetKeyValue(i, KeyVariant, ValueVariant) then
                Client.DefaultRequestHeaders.Add(Format(KeyVariant), Format(ValueVariant));

        if HttpTimeout <> 0 then
            Client.Timeout(HttpTimeout);

        Client.Send(Request, Response);

        Response.Content().ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then begin
            Response.Content().ReadAs(ErrorBodyContent);
            Error(RequestErr, Response.HttpStatusCode(), ErrorBodyContent);
        end;

        exit(ResponseText);
    end;

    var
        RequestErr: Label 'Request failed with HTTP Code:: %1 Request Body:: %2', Comment = '%1 = HttpCode, %2 = RequestBody';
        UnsupportedContentToSendErr: Label 'Unsuportted content to send.';
        ContentTypeKeyLbl: Label 'Content-Type', Locked = true;
}
