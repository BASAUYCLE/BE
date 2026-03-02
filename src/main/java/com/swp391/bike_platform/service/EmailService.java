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

    @Value("${app.logo-url:}")
    private String logoUrl;

    // ==================== PUBLIC METHODS ====================

    /**
     * Send verification approved email to user
     */
    @Async
    public void sendVerificationApprovedEmail(User user) {
        String subject = "Tài khoản của bạn đã được xác minh - BaSauCycle";
        String body = """
                <p>Xin chào <strong>%s</strong>,</p>
                <p>Chúng tôi vui mừng thông báo rằng tài khoản của bạn trên <strong>Ba Sáu Cycle</strong> đã được xác minh thành công!</p>
                <p>Bây giờ bạn có thể:</p>
                <ul>
                    <li>Đăng bài bán xe đạp cũ</li>
                    <li>Tham gia mua bán trên nền tảng</li>
                    <li>Sử dụng đầy đủ các tính năng</li>
                </ul>
                <p>Cảm ơn bạn đã tin tưởng sử dụng dịch vụ của chúng tôi!</p>
                %s
                """
                .formatted(
                        user.getFullName(),
                        buildButton("http://localhost:5173/login", "Đăng nhập ngay"));
        sendHtmlEmail(user.getEmail(), subject,
                buildFullTemplate("Xác minh thành công", "Tài khoản của bạn đã được xác minh", body));
    }

    /**
     * Send verification rejected email to user
     */
    @Async
    public void sendVerificationRejectedEmail(User user, String reason) {
        String body = """
                <p>Xin chào <strong>%s</strong>,</p>
                <p>Rất tiếc, yêu cầu xác minh tài khoản của bạn trên <strong>Ba Sáu Cycle</strong> chưa được chấp thuận.</p>
                <div style="background: #fff3cd; border-left: 4px solid #e6a817; padding: 15px; margin: 20px 0; border-radius: 4px;">
                    <strong>Lý do:</strong>
                    <p style="margin: 8px 0 0;">%s</p>
                </div>
                <p>Bạn có thể cập nhật thông tin và gửi lại yêu cầu xác minh:</p>
                <ul>
                    <li>Cập nhật ảnh CCCD rõ ràng hơn</li>
                    <li>Đảm bảo thông tin chính xác</li>
                    <li>Liên hệ hỗ trợ nếu cần giúp đỡ</li>
                </ul>
                %s
                """
                .formatted(
                        user.getFullName(),
                        reason != null ? reason : "Không có lý do cụ thể",
                        buildButton("http://localhost:5173/profile", "Cập nhật thông tin"));
        String subject = "Tài khoản chưa được xác minh - Ba Sáu Cycle";
        sendHtmlEmail(user.getEmail(), subject,
                buildFullTemplate("Thông báo", "Tài khoản của bạn chưa được xác minh", body));
    }

    /**
     * Send password reset email with reset link
     */
    @Async
    public void sendPasswordResetEmail(User user, String resetLink) {
        String body = """
                <p>Xin chào <strong>%s</strong>,</p>
                <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn trên <strong>Ba Sáu Cycle</strong>.</p>
                <p>Nhấn vào nút bên dưới để đặt lại mật khẩu:</p>
                %s
                <div style="background: #fff3cd; border-left: 4px solid #e6a817; padding: 15px; margin: 20px 0; border-radius: 4px;">
                    <strong>Lưu ý:</strong>
                    <p style="margin: 8px 0 0;">Link này sẽ hết hạn sau <strong>15 phút</strong>. Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</p>
                </div>
                <p style="color: #888; font-size: 13px;">Nếu nút không hoạt động, bạn có thể copy đường link sau vào trình duyệt:</p>
                <p style="word-break: break-all; font-size: 12px; color: #00C897;">%s</p>
                """
                .formatted(
                        user.getFullName(),
                        buildButton(resetLink, "Đặt lại mật khẩu"),
                        resetLink);
        String subject = "Đặt lại mật khẩu - Ba Sáu Cycle";
        sendHtmlEmail(user.getEmail(), subject,
                buildFullTemplate("Đặt lại mật khẩu", "Yêu cầu thay đổi mật khẩu của bạn", body));
    }

    // ==================== PRIVATE HELPERS ====================

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

    private String buildButton(String url, String text) {
        return """
                <p style="text-align: center; margin: 25px 0;">
                    <a href="%s" style="display: inline-block; background: #00C897; color: #ffffff; padding: 14px 40px; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 15px;">%s</a>
                </p>
                """
                .formatted(url, text);
    }

    private String buildFullTemplate(String headerTitle, String headerSubtitle, String bodyContent) {
        String logoHtml = "";
        if (logoUrl != null && !logoUrl.isBlank()) {
            logoHtml = """
                    <img src="%s" alt="Ba Sáu Cycle" style="max-width: 80px; margin-bottom: 15px;" />
                    """.formatted(logoUrl);
        }

        return """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                </head>
                <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Arial, sans-serif; background-color: #f4f6f8; color: #333;">
                    <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" style="background-color: #f4f6f8; padding: 30px 0;">
                        <tr>
                            <td align="center">
                                <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="max-width: 600px; width: 100%%;">
                                    <!-- Header -->
                                    <tr>
                                        <td style="background: linear-gradient(135deg, #00C897, #00B386); padding: 35px 30px; text-align: center; border-radius: 12px 12px 0 0;">
                                            %s
                                            <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 700;">%s</h1>
                                            <p style="margin: 8px 0 0; color: rgba(255,255,255,0.9); font-size: 14px;">%s</p>
                                        </td>
                                    </tr>
                                    <!-- Body -->
                                    <tr>
                                        <td style="background: #ffffff; padding: 35px 30px; font-size: 15px; line-height: 1.7;">
                                            %s
                                        </td>
                                    </tr>
                                    <!-- Footer -->
                                    <tr>
                                        <td style="background: #fafafa; padding: 20px 30px; text-align: center; border-radius: 0 0 12px 12px; border-top: 1px solid #eee;">
                                            <p style="margin: 0; color: #999; font-size: 12px;">&copy; 2026 Ba Sáu Cycle - BASAUYCLE Team</p>
                                            <p style="margin: 5px 0 0; color: #999; font-size: 12px;">Email này được gửi tự động, vui lòng không trả lời.</p>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </table>
                </body>
                </html>
                """
                .formatted(logoHtml, headerTitle, headerSubtitle, bodyContent);
    }
}
