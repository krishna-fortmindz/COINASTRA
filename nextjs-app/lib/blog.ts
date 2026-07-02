import fs from "fs";
import path from "path";
import matter from "gray-matter";
import { marked } from "marked";

const POSTS_DIR = path.join(process.cwd(), "content/blog");

export interface BlogPost {
  slug: string;
  title: string;
  excerpt: string;
  category: string;
  readTime: string;
  date: string;
  dateISO: string;
  featured: boolean;
  author: string;
  authorTitle: string;
  content: string;
}

export interface BlogPostMeta extends Omit<BlogPost, "content"> {}

export function getAllPosts(): BlogPostMeta[] {
  const files = fs.readdirSync(POSTS_DIR).filter((f) => f.endsWith(".md"));

  return files
    .map((file) => {
      const raw = fs.readFileSync(path.join(POSTS_DIR, file), "utf-8");
      const { data } = matter(raw);
      return data as BlogPostMeta;
    })
    .sort((a, b) => new Date(b.dateISO).getTime() - new Date(a.dateISO).getTime());
}

export function getPostBySlug(slug: string): BlogPost | null {
  const filePath = path.join(POSTS_DIR, `${slug}.md`);
  if (!fs.existsSync(filePath)) return null;

  const raw = fs.readFileSync(filePath, "utf-8");
  const { data, content } = matter(raw);

  const htmlContent = marked(content) as string;

  return {
    ...(data as BlogPostMeta),
    content: htmlContent,
  };
}

export function getAllSlugs(): string[] {
  return fs
    .readdirSync(POSTS_DIR)
    .filter((f) => f.endsWith(".md"))
    .map((f) => f.replace(".md", ""));
}
