export interface SvgAsset {
  id: string;
  user_id: string;
  name: string;
  svg_code: string;
  tags: string[];
  category: string;
  is_favorite: boolean;
  view_count: number;
  is_private: boolean;
  status: "pending" | "approved" | "rejected";
  created_at: string;
  updated_at: string;
  // Joined from svgbox_profiles (present when fetched with creator info)
  creator?: {
    id?: string;
    username: string | null;
    display_name: string | null;
  } | null;
}

export interface User {
  id: string;
  email: string;
  role: "user" | "admin";
  username: string | null;
}

export interface Profile {
  id: string;
  username: string | null;
  display_name: string | null;
  avatar_svg: string | null;
  bio: string | null;
  phone: string | null;
  website: string | null;
  twitter: string | null;
  instagram: string | null;
  github: string | null;
  role: "user" | "admin";
  last_seen_at: string | null;
  created_at: string;
  updated_at: string;
}
