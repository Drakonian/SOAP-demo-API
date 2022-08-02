page 81601 "SDA Temperature Converter"
{
    Caption = 'Temperature Converter';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(SOAPVersion; SOAPVersion)
                {
                    ApplicationArea = All;
                    Caption = 'SOAP Version';
                    ToolTip = 'SOAP Version';
                }
                field(Temperature; Temperature)
                {
                    ApplicationArea = All;
                    Caption = 'Temperature';
                    ToolTip = 'Temperature';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CelsiustoFarenheit)
            {
                ApplicationArea = All;
                Image = PreviousRecord;
                Caption = 'Celsius to Farenheit';
                ToolTip = 'Celsius to Farenheit';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                trigger OnAction()
                var
                    TempConver: Codeunit "SDA Temperature Conversion API";
                    NewTemperature: Text;
                begin
                    NewTemperature := TempConver.Convert(Enum::"SDA Temperature Convert Type"::"To Farenheit", SOAPVersion, Temperature);
                    Message(ResultLbl, Temperature, CelsiusLbl, NewTemperature, FarenheitLbl);
                end;
            }
            action(FarenheittoCelsius)
            {
                ApplicationArea = All;
                Image = NextRecord;
                Caption = 'Farenheit to Celsius';
                ToolTip = 'Farenheit to Celsius';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                trigger OnAction()
                var
                    TempConver: Codeunit "SDA Temperature Conversion API";
                    NewTemperature: Text;
                begin
                    NewTemperature := TempConver.Convert(Enum::"SDA Temperature Convert Type"::"To Celsius", SOAPVersion, Temperature);
                    Message(ResultLbl, Temperature, FarenheitLbl, NewTemperature, CelsiusLbl);
                end;
            }
        }
    }

    var
        SOAPVersion: Enum "SDA SOAP Version";
        Temperature: Integer;
        CelsiusLbl: Label 'Celsius';
        FarenheitLbl: Label 'Farenheit';
        ResultLbl: Label '%1 degrees %2 equals %3 degress %4.', Comment = '%1 = OldTemperature, %2 = OldDegreesType, %3 = NewTemerature, %4 = NewDegreesType';
}
