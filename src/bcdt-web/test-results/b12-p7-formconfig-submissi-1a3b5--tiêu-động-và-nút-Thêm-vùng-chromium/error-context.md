# Page snapshot

```yaml
- generic [ref=e6]:
  - generic [ref=e7]:
    - img "appstore" [ref=e8]:
      - img [ref=e9]
    - heading "BCDT" [level=2] [ref=e11]
    - text: Hệ thống báo cáo
  - generic [ref=e12]:
    - generic [ref=e14]:
      - generic "Tên đăng nhập" [ref=e16]: "* Tên đăng nhập"
      - textbox "* Tên đăng nhập" [ref=e20]:
        - /placeholder: Tên đăng nhập
        - text: admin
    - generic [ref=e22]:
      - generic "Mật khẩu" [ref=e24]: "* Mật khẩu"
      - generic [ref=e28]:
        - textbox "* Mật khẩu" [ref=e29]:
          - /placeholder: Mật khẩu
          - text: Admin@123
        - img "eye-invisible" [ref=e31] [cursor=pointer]:
          - img [ref=e32]
    - generic [ref=e35]: Lỗi hệ thống, vui lòng thử lại sau.
    - button "Đăng nhập" [active] [ref=e41] [cursor=pointer]:
      - generic [ref=e42]: Đăng nhập
```