codeunit 81602 "SDA Temperature Conversion API"
{
    procedure Convert(ConvertType: Enum "SDA Temperature Convert Type"; SoapVersion: Enum "SDA SOAP Version"; Temperature: Integer) NewTemperature: Text
    var
        DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper";
        BaseXMLDoc: XmlDocument;
        XMLElem: XmlElement;
        BodyNode: XmlNode;
        ResultXPath: Text;
        ContentToSend: Text;
        ContentType: Text;
        Result: Text;
    begin
        //Generate base XML request based on SOAP version
        //w3schools temperature converter support SOAP 1.1 and SOAP 1.2
        //depending on the SOAP version, we need to choose the correct namespace
        //SOAPAction is required for SOAP 1.1
        case SoapVersion of
            SoapVersion::soap:
                begin
                    BaseXMLDoc := CreateBaseXMLDoc(Format(SoapVersion), SOAP11NamespaceURILbl);
                    ContentType := SOAP11XMLContentTypeLbl;
                    DictionaryDefaultHeaders.Set('SOAPAction', '');
                end;
            SoapVersion::soap12:
                begin
                    BaseXMLDoc := CreateBaseXMLDoc(Format(SoapVersion), SOAP12NamespaceUriLbl);
                    ContentType := SOAP12XMLContentTypeLbl;
                end;
        end;

        //Generate body of request XML document in XMLElem variable
        //AddChildElementWithTxtValue() used for append child node to parent (first param)
        //Fill ResultXPath variable based on Convert Type
        //Set related SOAPAction for SOAP 1.1
        case ConvertType of
            ConvertType::"To Celsius":
                begin
                    XMLElem := XmlElement.Create('FahrenheitToCelsius', W3BaseNamespaceUriLbl);
                    AddChildElementWithTxtValue(XMLElem, 'Fahrenheit', W3BaseNamespaceUriLbl, Format(Temperature));
                    ResultXPath := BodyXPathLbl + LocalXPathSeparatorLbl + StrSubstNo(LocalXPathSignatureLbl, 'FahrenheitToCelsiusResponse') +
                                    LocalXPathSeparatorLbl + StrSubstNo(LocalXPathSignatureLbl, 'FahrenheitToCelsiusResult');
                    if DictionaryDefaultHeaders.ContainsKey('SOAPAction') then
                        DictionaryDefaultHeaders.Set('SOAPAction', W3BaseNamespaceUriLbl + 'FahrenheitToCelsius');
                end;
            ConvertType::"To Farenheit":
                begin
                    XMLElem := XmlElement.Create('CelsiusToFahrenheit', W3BaseNamespaceUriLbl);
                    AddChildElementWithTxtValue(XMLElem, 'Celsius', W3BaseNamespaceUriLbl, Format(Temperature));
                    ResultXPath := BodyXPathLbl + LocalXPathSeparatorLbl + StrSubstNo(LocalXPathSignatureLbl, 'CelsiusToFahrenheitResponse') +
                                    LocalXPathSeparatorLbl + StrSubstNo(LocalXPathSignatureLbl, 'CelsiusToFahrenheitResult');
                    if DictionaryDefaultHeaders.ContainsKey('SOAPAction') then
                        DictionaryDefaultHeaders.Set('SOAPAction', W3BaseNamespaceUriLbl + 'CelsiusToFahrenheit');
                end;
        end;

        //Append body of request XMLElem to base request XML document
        BaseXMLDoc.SelectSingleNode(BodyXPathLbl, BodyNode);
        BodyNode.AsXmlElement().Add(XMLElem);
        BaseXMLDoc.WriteTo(ContentToSend);

        //Send request XML Document and write result to text variable
        Result := SendTemperatureConversionAPIRequest(ContentToSend, ContentType, DictionaryDefaultHeaders);

        //Read result XML to find result temperature from ResultXPath
        NewTemperature := GetValueFromXML(Result, ResultXPath);

        //Handle error in case of success response status code (200)
        if NewTemperature = ErrorLbl then
            Error(ErrorLbl);
    end;

    local procedure SendTemperatureConversionAPIRequest(ContentToSend: Text; ContentType: Text; DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper"): Text
    var
        APIMgt: Codeunit "SDA API Mgt";
    begin
        exit(APIMgt.SendRequest(contentToSend, Enum::"Http Request Type"::POST,
                    W3BaseNamespaceUriLbl + W3ActionUriLbl,
                    ContentType, DictionaryDefaultHeaders));
    end;

    procedure CreateBaseXMLDoc(NamespacePrefix: Text; NamespaceUri: Text): XmlDocument
    var
        XMLDoc: XmlDocument;
        XMLDec: XmlDeclaration;
        XMLElem: XmlElement;
        XMLElem2: XmlElement;
        XMLAtr: XmlAttribute;
    begin
        XMLDoc := XmlDocument.Create();

        XMLDec := XmlDeclaration.Create('1.0', 'UTF-8', 'yes');
        XMLDoc.SetDeclaration(XMLDec);

        xmlElem := xmlElement.Create('Envelope', NamespaceUri);

        XMLAtr := XmlAttribute.CreateNamespaceDeclaration('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        XMLElem.Add(XMLAtr);
        XMLAtr := XmlAttribute.CreateNamespaceDeclaration('xsd', 'http://www.w3.org/2001/XMLSchema');
        XMLElem.Add(XMLAtr);
        XMLAtr := XmlAttribute.CreateNamespaceDeclaration(NamespacePrefix, NamespaceUri);
        XMLElem.Add(XMLAtr);

        xmlElem2 := XmlElement.Create('Header', NamespaceUri);
        xmlElem.Add(xmlElem2);

        Clear(xmlElem2);
        xmlElem2 := XmlElement.Create('Body', NamespaceUri);
        xmlElem2.Add(xmlText.Create(''));

        xmlElem.Add(xmlElem2);
        xmlDoc.Add(xmlElem);

        exit(XMLDoc);
    end;

    local procedure AddChildElementWithTxtValue(var inXMLElem: XmlElement; LocalName: Text; NamespaceUri: Text; inValue: Text);
    var
        CData: XmlCData;
    begin
        CData := XmlCData.Create('');
        AddChildElementWithCdataTxtValue(inXMLElem, LocalName, NamespaceUri, inValue, CData)
    end;

    local procedure AddChildElementWithCdataTxtValue(var inXMLElem: XmlElement; LocalName: Text; NamespaceUri: Text; inValue: Text; CData: XmlCData)
    var
        XMLEelem: XmlElement;
    begin
        if NamespaceUri <> '' then
            XMLEelem := XmlElement.Create(LocalName, NamespaceUri)
        else
            XMLEelem := XmlElement.Create(LocalName);
        XMLEelem.Add(xmlText.Create(inValue));
        if CData.Value() <> '' then
            XMLEelem.Add(CData);
        inXMLElem.Add(XMLEelem);
    end;

    procedure GetValueFromXML(Content: Text; pNodePath: Text): Text
    var
        XMLRootNode: XmlNode;
        XMLChildNode: XmlNode;
        XMLElem: XmlElement;
    begin
        GetRootNode(ConvertTextToXmlDocument(Content), XMLRootNode);

        XMLRootNode.SelectSingleNode(pNodePath, XMLChildNode);
        XMLElem := XMLChildNode.AsXmlElement();
        exit(XMLElem.InnerText());
    end;

    procedure ConvertTextToXmlDocument(Content: Text): XmlDocument
    var
        XmlDoc: XmlDocument;
    begin
        if XmlDocument.ReadFrom(Content, XmlDoc) then
            exit(XmlDoc);
    end;

    procedure GetRootNode(pXMLDocument: XmlDocument; var pFoundXMLNode: XmlNode)
    var
        lXmlElement: XmlElement;
    begin
        pXMLDocument.GetRoot(lXmlElement);
        pFoundXMLNode := lXmlElement.AsXmlNode();
    end;

    var
        SOAP11NamespaceURILbl: Label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
        SOAP12NamespaceUriLbl: Label 'http://www.w3.org/2003/05/soap-envelope', Locked = true;
        W3BaseNamespaceUriLbl: Label 'https://www.w3schools.com/xml/', Locked = true;
        SOAP11XMLContentTypeLbl: Label 'text/xml; charset=utf-8', Locked = true;
        SOAP12XMLContentTypeLbl: Label 'application/soap+xml; charset=utf-8', Locked = true;
        W3ActionUriLbl: Label 'tempconvert.asmx', Locked = true;
        LocalXPathSignatureLbl: Label '[local-name()="%1"]', Locked = true;
        LocalXPathSeparatorLbl: Label '/*', Locked = true;
        BodyXPathLbl: Label '/*[local-name()="Envelope"]/*[local-name()="Body"]', Locked = true;
        ErrorLbl: Label 'Error', Locked = true;
}
