*** Settings ***

Library         SeleniumLibrary  timeout=10  implicit_wait=0

Test Setup      Test Setup
Test Teardown   Close Browser


*** Test Cases ***

Scenario: Open Headless Browser
  Go To  https://google.com
  Wait until page contains  Google
  Page should contain  Google


*** Keywords ***

Test Setup
  # Open browser  browser=headlesschrome  url=https://google.com
  ${options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
  Call Method    ${options}  add_argument  --headless
  Call Method    ${options}  add_argument  --no-sandbox
  Create WebDriver  Chrome  chrome_options=${options}
