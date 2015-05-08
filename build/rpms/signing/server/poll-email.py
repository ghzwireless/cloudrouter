#!/usr/bin/python
import email
import getpass, imaplib
import os
import sys
import subprocess
import traceback

userName = 'cloudroutersign'
passwd = 'CHANGEME'

try:
    imapSession = imaplib.IMAP4_SSL('imap.gmail.com')
    typ, accountDetails = imapSession.login(userName, passwd)
    if typ != 'OK':
        print 'Not able to sign in!'
        raise
    
    imapSession.select('[Gmail]/All Mail')
    typ, data = imapSession.search(None, '(UNSEEN)')
    if typ != 'OK':
        print 'Error searching Inbox.'
        raise
    
    # Iterating over all emails
    for msgId in data[0].split():
        typ, messageParts = imapSession.fetch(msgId, '(RFC822)')
        if typ != 'OK':
            print 'Error fetching mail.'
            raise

        emailBody = messageParts[0][1]
        mail = email.message_from_string(emailBody)
	subject = mail.get('subject')
        body = mail.get_payload()
        open('build.txt', 'wt').write(subject)
        open('build.sig', 'wt').write(body)
        os.system('./process-email.sh')

    imapSession.close()
    imapSession.logout()
except :
    print traceback.format_exc()
    print "Unexpected error:", sys.exc_info()[0]
