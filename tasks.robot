*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.RobotLogListener
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.PDF
Library             Screenshot
Library             RPA.Robocorp.Vault
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.JSON


*** Variables ***
${url}              https://robotsparebinindustries.com/#/robot-order
${img_folder}       ${output_folder}${/}image_files
${pdf_folder}       ${output_folder}${/}pdf_files
${output_folder}    ${CURDIR}${/}output
${orders_file}      ${CURDIR}${/}orders.csv
${zip_file}         ${output_folder}${/}pdf_archive.zip
${csv_url}          https://robotsparebinindustries.com/orders.csv
${alert_danger}     //div[contains(@class, 'alert-danger')]


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    ${url}

Get orders
    Download    ${csv_url}    ${orders_file}    overwrite=True
    ${table}=    Read table from CSV    ${orders_file}    True
    RETURN    ${table}

Close the annoying modal
    Set Local Variable    ${btn_yep}    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait Until Element Is Visible    ${btn_yep}
    Click Button    ${btn_yep}

Fill the form
    [Arguments]    ${row}
    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id="address"]
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Select From List By Value    ${input_head}    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    ${input_legs}    ${row}[Legs]
    Input Text    ${input_address}    ${row}[Address]

Preview the robot
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Click Button    ${btn_preview}
    Wait Until Element Is Visible    ${img_preview}

Try again if keyword failed
    [Arguments]    ${keyword}
    Wait Until Keyword Succeeds    5x    1 sec    ${keyword}

Submit the order
    Click button Order
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${alert_danger}
    IF    ${status}    Try again if keyword failed    Click Button Order

Click button Order
    Click Element    id:order

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${alert_danger}
    IF    ${status}    Try again if keyword failed    Click button Order
    ${display_Order}=    Run Keyword And Return Status    Page Should Contain Element    id:order
    IF    ${display_Order}    Try again if keyword failed    Click button Order
    ${pdf}=    Set Variable    ${pdf_folder}${/}receipt_${order_number}.pdf
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf}
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Set Local Variable    ${screenshot}    ${img_folder}${/}${order_number}.png
    Wait Until Element Is Visible    id:receipt
    Screenshot    id:robot-preview-image    ${screenshot}
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${alert_danger}
    IF    ${status}    Try again if keyword failed    Click Button Order
    Wait Until Element Is Visible    id:receipt
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}    ${pdf}

Screenshot the results
    Screenshot    css:div.sales-summary    ${OUTPUT_DIR}${/}sales_summary.png

Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}pdf_files    receipts.zip

Click Button Order Another
    ${variable}=    Click Element    id:order-another

Go to order another robot
    ${is_another}=    Run Keyword And Return Status    Page Should Contain Element    id:order-another
    IF    ${is_another}
        Try again if keyword failed    Click Button Order Another
    END

Read some data from a vault
    ${secret}=    Get Secret    credentials
    Log    Name is ${secret}[name]    console=${TRUE}
