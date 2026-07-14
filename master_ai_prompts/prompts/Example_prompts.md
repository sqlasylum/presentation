# Example AI Prompts

## Thought Prompts

- Review the code and verify I have no PII, secrets, or other personal details stored inside the code.
- Check my code to see if you can find a way to optimize or make the code better.
- Review the code like I had only $100 to spend on the server that will run this. If you believe it will cost more than that, let me know.
- Treat the code like you were an auditor and needed to know what this system was doing at any time. What would you change about it?

---

## Testing Prompts

- Write a validation script that verifies the functionality of the procedure you just wrote.
- Create a script that validates all the tables are created.
- Make sure to return the output of the procedure so I can review and validate the data.
- Create a simple script that can test the performance of the system by calling the functions frequently.

---

## Example App

### QR Code Scanner

This new directory is meant to house a program to handle scanning QR codes at an event. The QR codes will be on the badge of the attendees. Sponsors will scan the QR code with any phone, and that will take them to a link to a website with a service behind the site.

The website will offer a login only if the sponsor has not already logged in. Once they have logged in they won't need to log in again. Login can be as simple as providing an email address — it does not need to be secured. The service will store the ID from the QR code and the email address that scanned it. It needs to store this in a simple PostgreSQL database.

This all needs to be created in Terraform so it can be deployed into a Rancher image or Docker image. This will either build a box in AWS or locally on a computer. All of this should be open source, and the code should be checked into Git.
