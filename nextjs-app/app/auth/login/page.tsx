import type { Metadata } from "next";
import AuthLayout from "@/components/auth/AuthLayout";
import LoginForm from "@/components/auth/LoginForm";

export const metadata: Metadata = {
  title: "Log in",
  description: "Sign in to your Coinastra account.",
  robots: { index: false, follow: false },
};

export default function LoginPage() {
  return (
    <AuthLayout
      title="Welcome back"
      subtitle="Sign in to your Coinastra account"
    >
      <LoginForm />
    </AuthLayout>
  );
}
