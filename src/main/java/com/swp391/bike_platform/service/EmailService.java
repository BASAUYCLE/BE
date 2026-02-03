package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    /**
     * Send verification approved email to user
     */
    @Async
    public void sendVerificationApprovedEmail(User user) {
        String subject = "🎉 Tài khoản của bạn đã được xác minh - Bike Platform";
        String htmlContent = buildApprovedEmailTemplate(user);
        sendHtmlEmail(user.getEmail(), subject, htmlContent);
    }

    /**
     * Send verification rejected email to user
     */
    @Async
    public void sendVerificationRejectedEmail(User user, String reason) {
        String subject = "⚠️ Tài khoản của bạn chưa được xác minh - Bike Platform";
        String htmlContent = buildRejectedEmailTemplate(user, reason);
        sendHtmlEmail(user.getEmail(), subject, htmlContent);
    }

    /**
     * Send HTML email
     */
    private void sendHtmlEmail(String to, String subject, String htmlContent) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            log.info("Email sent successfully to: {}", to);
        } catch (MessagingException e) {
            log.error("Failed to send email to {}: {}", to, e.getMessage());
            throw new AppException(ErrorCode.EMAIL_SEND_FAILED);
        }
    }

    private String buildApprovedEmailTemplate(User user) {
        return """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                        .header { background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                        .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }
                        .button { display: inline-block; background: #28a745; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin-top: 20px; }
                        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>🎉 Chúc mừng!</h1>
                            <p>Tài khoản của bạn đã được xác minh thành công</p>
                        </div>
                        <div class="content">
                            <p>Xin chào <strong>%s</strong>,</p>
                            <p>Chúng tôi vui mừng thông báo rằng tài khoản của bạn trên <strong>Bike Platform</strong> đã được xác minh thành công!</p>
                            <p>Bây giờ bạn có thể:</p>
                            <ul>
                                <li>✅ Đăng bài bán xe đạp cũ</li>
                                <li>✅ Tham gia mua bán trên nền tảng</li>
                                <li>✅ Sử dụng đầy đủ các tính năng</li>
                            </ul>
                            <p>Cảm ơn bạn đã tin tưởng sử dụng dịch vụ của chúng tôi!</p>
                            <a href="http://localhost:3000/login" class="button">Đăng nhập ngay</a>
                        </div>
                        <div class="footer">
                            <p>© 2026 Bike Platform - BASAUYCLE Team</p>
                            <p>Email này được gửi tự động, vui lòng không trả lời.</p>
                        </div>
                    </div>
                </body>
                </html>
                """
                .formatted(user.getFullName());
    }

    private String buildRejectedEmailTemplate(User user, String reason) {
        return """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <style>
                        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                        .header { background: linear-gradient(135deg, #dc3545, #fd7e14); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                        .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }
                        .reason-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
                        .button { display: inline-block; background: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin-top: 20px; }
                        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>⚠️ Thông báo</h1>
                            <p>Tài khoản của bạn chưa được xác minh</p>
                        </div>
                        <div class="content">
                            <p>Xin chào <strong>%s</strong>,</p>
                            <p>Rất tiếc, yêu cầu xác minh tài khoản của bạn trên <strong>Bike Platform</strong> chưa được chấp thuận.</p>

                            <div class="reason-box">
                                <strong>📝 Lý do:</strong>
                                <p>%s</p>
                            </div>

                            <p>Bạn có thể cập nhật thông tin và gửi lại yêu cầu xác minh:</p>
                            <ul>
                                <li>Cập nhật ảnh CCCD rõ ràng hơn</li>
                                <li>Đảm bảo thông tin chính xác</li>
                                <li>Liên hệ hỗ trợ nếu cần giúp đỡ</li>
                            </ul>

                            <a href="http://localhost:3000/profile" class="button">Cập nhật thông tin</a>
                        </div>
                        <div class="footer">
                            <p>© 2026 Bike Platform - BASAUYCLE Team</p>
                            <p>Email hỗ trợ: contact.basaucycle2026@gmail.com</p>
                        </div>
                    </div>
                </body>
                </html>
                """
                .formatted(user.getFullName(), reason != null ? reason : "Không có lý do cụ thể");
    }
}
