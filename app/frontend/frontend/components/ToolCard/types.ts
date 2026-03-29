export interface Tool {
  url: string;
  name: string;
  description: string;
  image?: string;
  disabled?: boolean;
  featured?: boolean;
  category?: string;
}
