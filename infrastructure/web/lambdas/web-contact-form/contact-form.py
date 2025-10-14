import json
import boto3
import os
import re
import urllib.request
import urllib.parse
from typing import Dict, Any, Optional
from botocore.exceptions import ClientError

# Inicializar cliente SES
ses = boto3.client('ses', region_name='us-east-1')

def verify_recaptcha(token: str, secret_key: str) -> bool:
    """
    Verifica el token de reCAPTCHA con Google
    
    Args:
        token: Token de reCAPTCHA del cliente
        secret_key: Secret key de reCAPTCHA
        
    Returns:
        True si la verificación es exitosa, False en caso contrario
    """
    if not secret_key or not token:
        print('reCAPTCHA not configured or token missing')
        return True  # Si no está configurado, permitir el envío
    
    try:
        url = 'https://www.google.com/recaptcha/api/siteverify'
        data = urllib.parse.urlencode({
            'secret': secret_key,
            'response': token
        }).encode()
        
        request = urllib.request.Request(url, data=data)
        response = urllib.request.urlopen(request)
        result = json.loads(response.read().decode())
        
        # reCAPTCHA v3 devuelve un score entre 0.0 y 1.0
        # 1.0 es muy probablemente un humano, 0.0 es muy probablemente un bot
        success = result.get('success', False)
        score = result.get('score', 0)
        
        print(f'reCAPTCHA verification: success={success}, score={score}')
        
        # Aceptar si success es True y score > 0.5
        return success and score > 0.5
        
    except Exception as e:
        print(f'Error verifying reCAPTCHA: {str(e)}')
        return False  # Rechazar en caso de error

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler para el formulario de contacto de Lisandro Ybarra
    
    Args:
        event: Evento de API Gateway
        context: Contexto de Lambda
        
    Returns:
        Respuesta HTTP con headers CORS y body JSON
    """
    
    # Configurar headers CORS
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
    }
    
    # API Gateway v2 uses requestContext.http.method
    http_method = event.get('requestContext', {}).get('http', {}).get('method', 
                                                        event.get('httpMethod', ''))
    
    # Manejar preflight OPTIONS request
    if http_method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': ''
        }
    
    try:
        # Debug logging
        print(f"Event received: {json.dumps(event)}")
        
        # Parsear el body del request
        body = json.loads(event.get('body', '{}'))
        print(f"Parsed body: {body}")
        
        name = body.get('name', '').strip()
        email = body.get('email', '').strip()
        message = body.get('message', '').strip()
        recaptcha_token = body.get('recaptchaToken', '')
        
        # Verificar reCAPTCHA
        recaptcha_secret = os.environ.get('RECAPTCHA_SECRET_KEY', '')
        if not verify_recaptcha(recaptcha_token, recaptcha_secret):
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Verificación de reCAPTCHA fallida. Por favor intenta nuevamente.'
                })
            }
        
        # Validación básica
        if not all([name, email, message]):
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Faltan campos requeridos: nombre, email y mensaje'
                })
            }
        
        # Validar formato de email
        if not is_valid_email(email):
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Formato de email inválido'
                })
            }
        
        # Obtener configuración desde variables de entorno
        contact_email = os.environ.get('CONTACT_EMAIL', 'info@yourdomain.com')
        forward_email = os.environ.get('FORWARD_EMAIL', '')
        website_url = os.environ.get('WEBSITE_URL', 'https://yourdomain.com')
        linkedin_url = os.environ.get('LINKEDIN_URL', 'https://www.linkedin.com/in/yourprofile/')
        github_url = os.environ.get('GITHUB_URL', 'https://github.com/yourusername')
        owner_name = os.environ.get('OWNER_NAME', 'Your Name')
        owner_title = os.environ.get('OWNER_TITLE', 'DevOps Engineer')
        
        # Preparar lista de destinatarios para el email de notificación
        recipient_emails = [contact_email]
        if forward_email:
            recipient_emails.append(forward_email)
        
        # Enviar email al administrador (y forward si está configurado)
        admin_email_sent = send_admin_notification(
            contact_email, recipient_emails, name, email, message, website_url
        )
        
        # Enviar email de confirmación al usuario (solo si SES no está en sandbox)
        confirmation_sent = True  # Assume success for now
        try:
            confirmation_sent = send_user_confirmation(
                contact_email, name, email, message, website_url, linkedin_url, 
                github_url, owner_name, owner_title
            )
        except ClientError as e:
            # Si SES está en sandbox mode, el email de confirmación fallará
            # pero aún podemos retornar éxito porque el email al admin fue enviado
            error_code = e.response['Error']['Code']
            if error_code == 'MessageRejected':
                print(f'Cannot send confirmation email (SES Sandbox mode): {str(e)}')
                confirmation_sent = False  # Not critical, admin email was sent
            else:
                raise  # Re-raise if it's a different error
        
        if admin_email_sent:
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'message': 'Mensaje enviado exitosamente' + 
                              ('' if confirmation_sent else ' (nota: email de confirmación no enviado)')
                })
            }
        else:
            raise Exception('Error al enviar el email de notificación')
            
    except json.JSONDecodeError as error:
        print(f'JSON decode error: {str(error)}')
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({
                'error': 'Formato JSON inválido'
            })
        }
    except ClientError as error:
        print(f'AWS SES error: {str(error)}')
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': f'Error de SES: {error.response["Error"]["Message"]}'
            })
        }
    except Exception as error:
        print(f'Error en Lambda: {str(error)}')
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': f'Error interno del servidor: {str(error)}'
            })
        }

def is_valid_email(email: str) -> bool:
    """
    Valida el formato de email usando regex
    
    Args:
        email: Email a validar
        
    Returns:
        True si el email es válido, False en caso contrario
    """
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def send_admin_notification(sender_email: str, recipient_emails: list, name: str, 
                           email: str, message: str, website_url: str) -> bool:
    """
    Envía email de notificación al administrador (y destinatarios adicionales)
    
    Args:
        sender_email: Email que aparecerá como remitente
        recipient_emails: Lista de emails destinatarios
        name: Nombre del usuario
        email: Email del usuario
        message: Mensaje del usuario
        website_url: URL del sitio web
        
    Returns:
        True si se envió exitosamente, False en caso contrario
    """
    try:
        subject = f'Nueva consulta de {name}'
        
        html_body = f"""
        <html>
        <head>
            <style>
                body {{ font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }}
                .header {{ background-color: #1976D2; background: linear-gradient(135deg, #1976D2 0%, #2196F3 100%); padding: 20px; text-align: center; }}
                .header h2 {{ color: #ffffff; margin: 0; }}
                .content {{ padding: 20px; background-color: #fff; }}
                .field {{ margin-bottom: 15px; padding: 10px; border-left: 3px solid #2196F3; background-color: #f8f9fa; }}
                .field strong {{ color: #1976D2; }}
                .footer {{ background-color: #263238; padding: 15px; text-align: center; font-size: 12px; color: #cfd8dc; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h2>📧 Nueva consulta recibida</h2>
            </div>
            <div class="content">
                <div class="field">
                    <strong>Nombre:</strong> {name}
                </div>
                <div class="field">
                    <strong>Email:</strong> {email}
                </div>
                <div class="field">
                    <strong>Mensaje:</strong><br>
                    {message.replace(chr(10), '<br>')}
                </div>
            </div>
            <div class="footer">
                <p>Enviado desde el formulario de contacto de {website_url.replace('https://', '').replace('http://', '')}</p>
            </div>
        </body>
        </html>
        """
        
        text_body = f"""
        Nueva consulta recibida
        
        Nombre: {name}
        Email: {email}
        Mensaje: {message}
        
        Enviado desde el formulario de contacto
        """
        
        response = ses.send_email(
            Source=sender_email,
            Destination={'ToAddresses': recipient_emails},
            Message={
                'Subject': {'Data': subject, 'Charset': 'UTF-8'},
                'Body': {
                    'Html': {'Data': html_body, 'Charset': 'UTF-8'},
                    'Text': {'Data': text_body, 'Charset': 'UTF-8'}
                }
            }
        )
        
        print(f'Email de notificación enviado a {", ".join(recipient_emails)}: {response["MessageId"]}')
        return True
        
    except ClientError as e:
        print(f'Error al enviar email de notificación: {e}')
        return False

def send_user_confirmation(admin_email: str, name: str, user_email: str, 
                          message: str, website_url: str, linkedin_url: str,
                          github_url: str, owner_name: str, owner_title: str) -> bool:
    """
    Envía email de confirmación al usuario
    
    Args:
        admin_email: Email del administrador (remitente)
        name: Nombre del usuario
        user_email: Email del usuario
        message: Mensaje del usuario
        website_url: URL del sitio web
        linkedin_url: URL de LinkedIn
        github_url: URL de GitHub
        owner_name: Nombre del propietario
        owner_title: Título del propietario
        
    Returns:
        True si se envió exitosamente, False en caso contrario
    """
    try:
        subject = f'Gracias por tu consulta - {owner_name}'
        
        html_body = f"""
        <html>
        <head>
            <style>
                body {{ font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }}
                .header {{ background-color: #1976D2; background: linear-gradient(135deg, #1976D2 0%, #2196F3 100%); padding: 20px; text-align: center; }}
                .header h2 {{ color: #ffffff; margin: 0; }}
                .content {{ padding: 20px; background-color: #fff; }}
                .message-box {{ background-color: #e3f2fd; padding: 15px; border-left: 4px solid #2196F3; margin: 20px 0; border-radius: 4px; }}
                .footer {{ background-color: #263238; padding: 15px; text-align: center; font-size: 12px; color: #cfd8dc; }}
                .footer p {{ margin: 5px 0; }}
                a {{ color: #2196F3; text-decoration: none; }}
                a:hover {{ text-decoration: underline; }}
                ul {{ padding-left: 20px; }}
                li {{ margin: 8px 0; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h2>💬 ¡Gracias por contactarme!</h2>
            </div>
            <div class="content">
                <p>Hola <strong>{name}</strong>,</p>
                <p>Hemos recibido tu consulta y nos pondremos en contacto contigo pronto.</p>
                
                <div class="message-box">
                    <strong>Tu mensaje:</strong><br>
                    {message.replace(chr(10), '<br>')}
                </div>
                
                <p>Mientras tanto, puedes:</p>
                <ul>
                    <li>Visitar mi <a href="{website_url}">sitio web</a></li>
                    <li>Conectar en <a href="{linkedin_url}">LinkedIn</a></li>
                    <li>Ver mi <a href="{github_url}">GitHub</a></li>
                </ul>
            </div>
            <div class="footer">
                <p>Saludos,<br><strong>{owner_name}</strong></p>
                <p>{owner_title}</p>
            </div>
        </body>
        </html>
        """
        
        text_body = f"""
        ¡Gracias por contactarnos!
        
        Hola {name},
        
        Hemos recibido tu consulta y nos pondremos en contacto contigo pronto.
        
        Tu mensaje:
        {message}
        
        Mientras tanto, puedes:
        - Visitar mi sitio web: {website_url}
        - Conectar en LinkedIn: {linkedin_url}
        - Ver mi GitHub: {github_url}
        
        Saludos,
        {owner_name}
        {owner_title}
        """
        
        response = ses.send_email(
            Source=admin_email,
            Destination={'ToAddresses': [user_email]},
            Message={
                'Subject': {'Data': subject, 'Charset': 'UTF-8'},
                'Body': {
                    'Html': {'Data': html_body, 'Charset': 'UTF-8'},
                    'Text': {'Data': text_body, 'Charset': 'UTF-8'}
                }
            }
        )
        
        print(f'Email de confirmación enviado: {response["MessageId"]}')
        return True
        
    except ClientError as e:
        print(f'Error al enviar email de confirmación: {e}')
        return False

def validate_input(name: str, email: str, message: str) -> Optional[str]:
    """
    Valida los campos de entrada
    
    Args:
        name: Nombre del usuario
        email: Email del usuario
        message: Mensaje del usuario
        
    Returns:
        Mensaje de error si hay validación fallida, None si es válido
    """
    if len(name) < 2:
        return 'El nombre debe tener al menos 2 caracteres'
    
    if len(name) > 100:
        return 'El nombre es demasiado largo'
    
    if len(message) < 10:
        return 'El mensaje debe tener al menos 10 caracteres'
    
    if len(message) > 1000:
        return 'El mensaje es demasiado largo'
    
    return None
