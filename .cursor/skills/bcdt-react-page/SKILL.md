---
name: bcdt-react-page
description: Create a new React page with DevExtreme components for BCDT frontend. Generates page component, data grid, hooks, and API client. Use when user says "tạo trang", "tạo page", "create page", or wants to add a new frontend page.
---

# BCDT React Page Generator

Create complete React page with DevExtreme components.

## Workflow

1. **Gather requirements**:
   - Page name and route
   - Page type: List, Detail, Form, Dashboard
   - Data source (API endpoint)
   - DevExtreme components needed
   - Actions (create, edit, delete, export)

2. **Generate files**:

### Page Component
```tsx
// src/pages/{Module}/{PageName}Page.tsx
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { use{Entity}List } from '@/hooks/use{Entity}';
import { {Entity}Grid } from '@/components/{Module}/{Entity}Grid';
import { PageHeader } from '@/components/common/PageHeader';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { ErrorMessage } from '@/components/common/ErrorMessage';

export const {PageName}Page: React.FC = () => {
  const navigate = useNavigate();
  const { data, isLoading, error, refetch } = use{Entity}List();

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} onRetry={refetch} />;

  const handleCreate = () => navigate('/{route}/new');
  const handleEdit = (id: number) => navigate(`/{route}/${id}`);

  return (
    <div className="page-container">
      <PageHeader 
        title="{PageTitle}"
        actions={[
          { label: 'Thêm mới', onClick: handleCreate, icon: 'plus' }
        ]}
      />
      <{Entity}Grid 
        data={data} 
        onEdit={handleEdit}
        onRefresh={refetch}
      />
    </div>
  );
};
```

### Data Grid Component
```tsx
// src/components/{Module}/{Entity}Grid.tsx
import React from 'react';
import DataGrid, { 
  Column, Paging, Pager, FilterRow, 
  SearchPanel, Export, Selection 
} from 'devextreme-react/data-grid';
import { {Entity}Dto } from '@/types/{entity}.types';

interface Props {
  data: {Entity}Dto[];
  onEdit: (id: number) => void;
  onRefresh: () => void;
}

export const {Entity}Grid: React.FC<Props> = ({ data, onEdit, onRefresh }) => {
  return (
    <DataGrid
      dataSource={data}
      keyExpr="id"
      showBorders
      columnAutoWidth
      allowColumnReordering
      onRowDblClick={(e) => onEdit(e.data.id)}
    >
      <FilterRow visible />
      <SearchPanel visible placeholder="Tìm kiếm..." />
      <Selection mode="multiple" />
      <Paging defaultPageSize={20} />
      <Pager showPageSizeSelector allowedPageSizes={[10, 20, 50]} showInfo />
      <Export enabled fileName="{entity}_list" />
      
      <Column dataField="id" caption="ID" width={80} />
      <Column dataField="name" caption="Tên" />
      <Column dataField="status" caption="Trạng thái" />
      <Column dataField="createdAt" caption="Ngày tạo" dataType="datetime" />
      <Column 
        type="buttons" 
        width={120}
        buttons={[
          { hint: 'Sửa', icon: 'edit', onClick: (e) => onEdit(e.row.data.id) },
          { hint: 'Xóa', icon: 'trash', onClick: (e) => handleDelete(e.row.data.id) }
        ]}
      />
    </DataGrid>
  );
};
```

### Custom Hook
```tsx
// src/hooks/use{Entity}.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { {entity}Api } from '@/api/{entity}Api';
import { {Entity}Filter } from '@/types/{entity}.types';

export const use{Entity}List = (filter?: {Entity}Filter) => {
  return useQuery({
    queryKey: ['{entity}s', filter],
    queryFn: () => {entity}Api.getList(filter),
  });
};

export const use{Entity} = (id: number) => {
  return useQuery({
    queryKey: ['{entity}', id],
    queryFn: () => {entity}Api.getById(id),
    enabled: !!id,
  });
};

export const useCreate{Entity} = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: {entity}Api.create,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['{entity}s'] }),
  });
};

export const useUpdate{Entity} = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }) => {entity}Api.update(id, data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['{entity}s'] }),
  });
};

export const useDelete{Entity} = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: {entity}Api.delete,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['{entity}s'] }),
  });
};
```

### API Client
```tsx
// src/api/{entity}Api.ts
import { apiClient } from './apiClient';
import { {Entity}Dto, Create{Entity}Request, Update{Entity}Request } from '@/types/{entity}.types';

export const {entity}Api = {
  getList: (filter?: {Entity}Filter) => 
    apiClient.get<{Entity}Dto[]>('/api/v1/{entity}s', { params: filter }),
  
  getById: (id: number) => 
    apiClient.get<{Entity}Dto>(`/api/v1/{entity}s/${id}`),
  
  create: (data: Create{Entity}Request) => 
    apiClient.post<{Entity}Dto>('/api/v1/{entity}s', data),
  
  update: (id: number, data: Update{Entity}Request) => 
    apiClient.put<{Entity}Dto>(`/api/v1/{entity}s/${id}`, data),
  
  delete: (id: number) => 
    apiClient.delete(`/api/v1/{entity}s/${id}`),
};
```

### Types
```tsx
// src/types/{entity}.types.ts
export interface {Entity}Dto {
  id: number;
  name: string;
  status: string;
  createdAt: string;
}

export interface Create{Entity}Request {
  name: string;
}

export interface Update{Entity}Request {
  name: string;
}

export interface {Entity}Filter {
  search?: string;
  status?: string;
  page?: number;
  pageSize?: number;
}
```

### Route Registration
```tsx
// Add to src/routes/index.tsx
{ path: '/{route}', element: <{PageName}Page /> },
{ path: '/{route}/:id', element: <{PageName}DetailPage /> },
```

## Checklist
- [ ] Page component
- [ ] Grid/Detail component
- [ ] Custom hooks (useQuery, useMutation)
- [ ] API client
- [ ] TypeScript types
- [ ] Route registration
- [ ] Menu item (if needed)
