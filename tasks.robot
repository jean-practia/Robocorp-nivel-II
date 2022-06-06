*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create news Directory
    Open the robot order website
    [Teardown]    Close the browser

*** Variables ***

${FILECSV}=     orders.csv
${FOLDERFILES}=        ${CURDIR}${/}output
${URLDOWNLOAD}=    https://robotsparebinindustries.com/orders.csv

*** Keywords ***
Create news Directory 
    ${existFolder}=    Does Directory Exist    ${CURDIR}${/}output${/}        # verifica se existe a pasta output

    IF    ${existFolder}

        Remove Directory    ${CURDIR}${/}output${/}    recursive=True        # deleta a pasta e subdiretorios(true)

        Create Directory    ${CURDIR}${/}output${/}
        Create Directory    ${CURDIR}${/}output${/}results    
        Create Directory    ${CURDIR}${/}output${/}results${/}receipt
        Create Directory    ${CURDIR}${/}output${/}results${/}imagesrobot
    ELSE
        Create Directory    ${CURDIR}${/}output${/}
        Create Directory    ${CURDIR}${/}output${/}results    
        Create Directory    ${CURDIR}${/}output${/}results${/}receipt
        Create Directory    ${CURDIR}${/}output${/}results${/}imagesrobot 
    END
     

Open the robot order website
    # Pega as credenciais local no arquivo vault

    ${secret}=    Get Secret    credentials
    ${secretUrl}    Set Variable    ${secret}[url]
   
    # Abre o site
    Open Available Browser    ${secretUrl}        maximized=true    
    # Download arquivo csv
    Download    ${URLDOWNLOAD}    overwrite=true

    @{orders}=    Read Table From Csv    ${FILECSV}    header=True    # le o csv como tabela
    
    
    FOR    ${row}    IN    @{orders}
            
            Close the annoyng modal
            
            Fill the form    ${row}

            Preveiw the robot

            Submit the order
                        
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]

            ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
           
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    

            Go to order another robot

    END
    Create a ZIP file of the receipts  


Close the annoyng modal
    # Clica no OK do popup
    Click Button    tag:.btn-dark
Fill the form
    # Preenche os campos do form
    [Arguments]    ${row}
   
    Select From List By Value    id: head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input        ${row}[Legs]
    Input Text    id: address    ${row}[Address]

Preveiw the robot
    #Click button preview
    Click Button    id: preview

Submit the order   
    #Click button order 
    Click Button    id: order  
          
    # Validate if click button order is ok        
    ${exist}=    Is Element Visible    id: order        
    Log To Console     variable result: ${exist}
    
    IF  ${exist}
        ${i}=    Set Variable    1   # contador =1
                 
        WHILE    ${exist} 
            
                Click Button    id: preview
                Click Button    id: order
                ${exist}=    Is Element Visible    id: order
                Log    ${exist}
                IF    ${exist} 
                    ${i}=    Evaluate    ${i} + 1        # incrementa contador
                ELSE
                    Exit For Loop If    "${exist}" == False        # vai sair do loop pq o booleano é false 
                END    
                
            END
                
        END

Go to order another robot
    #Clica no botão another robot
    Click Button    id: order-another

Store the receipt as a PDF file
    # Salva o recibo como pdf na pasta results/receipt
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt  
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${FOLDERFILES}${/}results${/}receipt${/}${row}.pdf    #salva o elemento html como pdf
    ${pdf}    Set Variable    ${FOLDERFILES}${/}results${/}receipt${/}${row}.pdf
    [Return]    ${pdf}    
    
Take a screenshot of the robot
    # Salva o screenshot como png na pasta results/imagesrobot
    [Arguments]    ${row}

    Screenshot    robot-preview-image    ${FOLDERFILES}${/}results${/}imagesrobot${/}${row}.png    # salva foto do elemento como png
    ${screenshot}    Set Variable    ${FOLDERFILES}${/}results${/}imagesrobot${/}${row}.png
    [Return]    ${screenshot}

Create a ZIP file of the receipts
    # Cria o zip com arquivos de recibos
    # Uso da library dialogs
    Add heading  *** Execution completed successfully ***
    Add icon    Success
    Add text input    message
    ...    label=What's your name?
    ...    placeholder=Enter your name here to include in the zip file
    ...    rows=1   
    ${result}=    Run dialog        # o que foi digitado na caixa de dialogo 
    Log To Console    Typed name:${result.message}
    
    Archive Folder With Zip    ${FOLDERFILES}${/}results${/}receipt    ${FOLDERFILES}${/}receipts_images_${result.message}.zip    # zipa a pasta dos recibos e salva com o nome digitado na caixa de diálogo


Embed the robot screenshot to the receipt PDF file
# Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    
    
        
    @{listpng}    Create List    ${screenshot}:align=center  # cria a lista

    Open Pdf    ${pdf}    # abre o pdf

    Add Files To Pdf    ${listpng}     ${pdf}       ${true}        # adiciona a imagem no arquivo do recibo

    Close Pdf         # fecha o pdf                                     
Close the browser
# Close the browser
    Close Browser



#Vamos analisar nosso código. Colocamos nossa tarefas dentro do for assim o 
#robô vai repetir essas ações enquanto tiver linhas na planilha para executar. 
#Fazendo com o que não precisássemos copiar e colar o 
#código várias vezes e evitando o erro de não executar alguma linha da planilha. 
    
